# Couch servers for users stuff.

require 'tmpdir'

namespace :tracemonkey do

  desc 'Build Tracemonkey'
  task :build => [:known_distro, 'environment:path', JS_LIB]

  file JS_LIB => [package_dep('/usr/bin/python' => 'python'), AUTOCONF_213] do
    src = "#{DEPS}/js_src"
    begin
      Dir.chdir src

      if DISTRO[0] == :slf
          sh 'autoconf-2.13'
      else
          sh 'autoconf2.13'
      end

      Dir.mktmpdir 'tracemonkey_build' do |dir|
        Dir.chdir dir do
          sh "#{src}/configure --prefix=#{BUILD} --without-x"
          sh 'make'
          sh 'make install'
        end
      end

      record_manifest 'tracemonkey'
    ensure
      Dir.chdir src
      sh 'make distclean' if File.exist? 'Makefile'
      sh 'git clean -df .'
    end
  end
end
