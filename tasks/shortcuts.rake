desc Rake::Task['build:couchdb'].comment
task :default => 'build:couchdb'

desc Rake::Task['environment:shell'].comment
task :sh => 'environment:shell'
