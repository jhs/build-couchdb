# Operating within the OS

namespace :environment do

  directory "#{BUILD}/bin"

  # Make sure the PATH is correct
  task :path => "#{BUILD}/bin" do
    ENV['PATH'] = "#{BUILD}/bin:#{ENV['PATH']}" unless ENV['PATH'].split(/:/).include? "#{BUILD}/bin"
  end

  desc 'Output a shell script suitable to use this software'
  task :code => :path do
    puts "export PATH=#{ENV['PATH']}"
  end

  desc 'Run a subshell with this environment loaded'
  task :shell => :path do
    sh "bash"
  end

end
