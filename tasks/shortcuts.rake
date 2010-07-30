desc Rake::Task['build:couchdb'].comment
task :default => 'build:couchdb'

desc Rake::Task['environment:shell'].comment
task :sh => 'environment:shell'

desc Rake::Task['environment:code'].comment
task :env => 'environment:code'
