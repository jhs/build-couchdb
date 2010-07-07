# Exporting the code for consumption
load File.dirname(__FILE__) + '/places.rake'

require 'pathname'
require 'fileutils'

namespace :export do

  # Inner function to export one Git checkout.
  task :component => :known_distro do
    raise "Must specify target=something, e.g. /tmp/couch" unless ENV['target']

    target = ENV['target']
    raise "Please remove #{target} firsts" unless !File.exists?(target) || (File.directory?(target) && Dir.glob("#{target}/*").empty?)
    FileUtils.mkdir_p target

    Dir.chdir ENV['source'] do
      sh "git checkout-index --all --prefix='#{target}/'"
      FileUtils.rm_f ["#{target}/.gitignore", "#{target}/.gitmodules"]
    end
  end

  desc 'Export this Git checkout into a normal directory tree'
  task :fs => :known_distro do

    Dir.chdir HERE do
      sh "git submodule init"
      sh "git submodule update"

      ENV['source'] = HERE
      Rake::Task['export:component'].execute
      FileUtils.rm_f "#{ENV['target']}/tasks/export.rake" # No need for this anymore.

      # This does not support foreach --recursive because the path would be calculated wrong.
      sh "git submodule foreach 'rake -f #{HERE}/Rakefile export:component source=#{HERE}/$path target=#{ENV['target']}/$path'"
    end
  end

  %w[ tar gzip bzip2 zip ].each do |compressor|
    desc "Export this Git checkout into a #{compressor} archive"
    task compressor => :fs do |task|
      Dir.chdir "#{ENV['target']}/.." do
        target = File.basename ENV['target']

        if task.name == 'export:zip'
          sh "zip -r #{target}.zip #{target}"
        else
          sh "tar cvf #{target}.tar #{target}"
          sh "#{compressor} -9 #{target}.tar" unless task.name == 'export:tar'
        end
      end

      FileUtils.rm_rf ENV['target']
    end
  end
end
