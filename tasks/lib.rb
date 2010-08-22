# Miscellaneous utilities

require 'find'
require 'tmpdir'

require File.dirname(__FILE__) + '/places'

def package_dep opts
  program_file, package = opts.to_a.first

  Rake.application.in_explicit_namespace(':') do
    task "package:#{package}" => :known_distro do
      unless [:ubuntu, :debian].include? DISTRO[0]
        puts "Skipping package requirement '#{package}' on a non-Linux platform"
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
	puts "Required: #{packages.inspect}"
  case DISTRO[0]
	when :opensuse
	  installed = %x[rpm -qa].split("\n")
	  packages.select{|pkg| ! installed.detect{|d| d =~ /^#{Regexp.escape(pkg)}/ } }.each do |package|
      # puts "Installing #{package} ..."
	    %x[sudo zypper install '#{package}']
    end
	else 
	  installed = `dpkg --list`.split("\n").map { |x| x.split[1] } # Hm, this is out of scope if defined outside.
	  packages.select{ |pkg| ! installed.include? pkg }.each do |package|
	    sh "sudo apt-get -y install #{package}"
	  end
  end
end

def canonical_path path
  path.gsub /[\.\d]*$/, ''
end


def ln_canonical path
  puts "#{path} => #{canonical_path path}"
  FileUtils.ln_sf path, canonical_path(path)
end


def with_autoconf ver
  files = %w[ autoconf autoheader autom4te ].map { |x| "#{BUILD}/bin/#{x}#{ver}" }

  begin
    files.each { |x| ln_canonical x }
    yield
  ensure
    files.each { |x| FileUtils.rm_f(canonical_path(x)) }
  end
end

def copy_parts opts
  Dir.chdir opts[:source] do
    sh "tar cf - #{opts[:dirs].join ' '} | tar xvf - --directory #{opts[:target]}"
  end
end

def in_build_dir label
  label = File.basename Dir.getwd if label.nil?
  Dir.mktmpdir "#{label}_build" do |dir|
    Dir.chdir dir do
      yield
    end
  end
end

def compress_beams source
  Find.find(source) do |path|
    if File.file?(path) && path.match(/\.beam$/) && ENV['skip_compress_beam'].nil?
      sh "gzip -9 '#{path}'"
      sh "mv '#{path}'.gz '#{path}'"
    end
  end
end

def record_manifest task_name
  return if ENV['manifest'].nil? || ENV['manifest'] == ""

  task_name = File.basename(task_name) if task_name =~ /\//

  sh "mkdir -p #{MANIFESTS}"
  seen = {}
  Dir.glob("#{MANIFESTS}/*").each do |manifest|
    File.new(manifest).each do |line|
      path = line.chomp
      raise "Woa! #{path} is in #{task_name} but was already seen in #{seen[path]}" if seen[path]
      seen[path] = File.basename(manifest)
    end
  end

  unseen = []
  Find.find(BUILD) do |path|
    if File.directory? path
      Find.prune if path == MANIFESTS
    else
      if seen[path]
        #puts "#{path} seen: #{seen[path]}"
      else
        unseen.push path
      end
    end
  end

  manifest = File.new("#{MANIFESTS}/#{task_name}", 'w')
  manifest.write(unseen.join("\n"))
  manifest.write("\n")
  manifest.close
end

def run_task name
  task = Rake::Task[name]
  task.reenable if task.methods.include?("reenable")
  task.invoke
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
