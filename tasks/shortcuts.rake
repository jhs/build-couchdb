desc Rake::Task['couchdb:build'].comment
task :default => 'couchdb:build'

desc Rake::Task['couchdb:build'].comment
task :couchdb => 'couchdb:build'

desc Rake::Task['environment:shell'].comment
task :sh => 'environment:shell'

desc Rake::Task['environment:code'].comment
task :env => 'environment:code'

desc Rake::Task['erlang:build'].comment
task :erlang => 'erlang:build'
