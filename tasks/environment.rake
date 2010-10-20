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

  desc 'Output the ./configure command to build couchdb'
  task :configure => :known_distro do
    if DISTRO[0] == :solaris
      run_task("environment:path")
      puts "export PATH=\"#{ENV['PATH']}\""
    else
      puts "export PATH=\"#{BUILD}/bin:$PATH\""
    end
    puts "export DYLD_LIBRARY_PATH=\"#{BUILD}/lib:$DYLD_LIBRARY_PATH\"" if DISTRO[0] == :osx
    puts "LDFLAGS='-R#{BUILD}/lib -L#{BUILD}/lib' CFLAGS='-I#{BUILD}/include/js -I#{BUILD}/lib/erlang/usr/include' ./configure"
  end

end
