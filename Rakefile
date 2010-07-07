# Master control of the build system
HERE = File.expand_path(File.dirname __FILE__)

require "#{HERE}/tasks/lib"
Dir[ File.dirname(__FILE__) + '/tasks/*.rake' ].each { |subtask| import subtask }
