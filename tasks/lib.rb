# Miscellaneous utilities

load File.dirname(__FILE__) + '/places.rake'

def package_dep opts
  program_file, package = opts.first

  Rake.application.in_explicit_namespace(':') do
    task "package:#{package}" => :known_distro do
      unless [:ubuntu, :debian].include? DISTRO[0]
        puts "WARNING: Skipping package requirement '#{package}' on a non-Linux platform"
      else
        installed = `dpkg --list`.split("\n").map { |x| x.split[1] } # Hm, this is out of scope if defined outside.
        if installed.none? { |pkg| pkg == package }
          sh "sudo apt-get -y install #{package}"
        end
      end
    end

    file program_file => "package:#{package}"
  end

  program_file
end

# Mark a program as authorized to listen on a low port in Linux.
def set_port_cap file
  return unless [:ubuntu, :debian].include? DISTRO[0]
  sh "sudo setcap cap_net_bind_service=+ep #{File.expand_path file}"
end

# TODO: Get rid of this. Packages should be installed as a dependency of other software, declared by package_dep().
def install packages
  installed = `dpkg --list`.split("\n").map { |x| x.split[1] } # Hm, this is out of scope if defined outside.
  packages.select{ |pkg| ! installed.include? pkg }.each do |package|
    sh "sudo apt-get -y install #{package}"
  end
end

module Rake
  module TaskManager
    def in_explicit_namespace(name)
      oldscope = @scope;
      @scope = Array.new();
      # build scope name list from name here
      ns = NameSpace.new(self, @scope);
      yield(ns)
      ns
      ensure
        @scope = oldscope;
    end
  end
end
