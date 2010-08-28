# Operating within the OS

namespace :environment do

  directory "#{BUILD}/bin"

  # Make sure the PATH is correct
  task :path => "#{BUILD}/bin" do
    ENV['PATH'] = "#{BUILD}/bin:#{ENV['PATH']}" unless ENV['PATH'].split(/:/).include? "#{BUILD}/bin"
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
  task :configure do
    puts "PATH=\"#{BUILD}/bin:$PATH\""
    puts "LDFLAGS='-R#{BUILD}/lib -L#{BUILD}/lib' CFLAGS='-I#{BUILD}/include/js -I#{BUILD}/lib/erlang/usr/include' ./configure"
  end

end
