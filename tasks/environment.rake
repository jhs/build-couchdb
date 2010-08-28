# Operating within the OS

namespace :environment do

  directory "#{BUILD}/bin"

  # Make sure the PATH is correct
  task :path => ["#{BUILD}/bin", :known_distro] do
    dirs = [ "#{BUILD}/bin" ]
    dirs = %w[ /opt/csw/gcc4/bin /opt/csw/bin /usr/ccs/bin ] + dirs if DISTRO[0] == :solaris

    old_path = ENV['PATH'].split(/:/)
    dirs.each do |dir|
      ENV['PATH'] = "#{dir}:#{ENV['PATH']}" unless old_path.include? dir
    end
  end

  desc 'Output a shell script suitable to use this software (best with --silent)'
  task :code => :path do
    puts "export PATH='#{ENV['PATH']}'"
  end

  desc 'Run a subshell with this environment loaded'
  task :shell => :path do
    sh "bash"
  end

end
