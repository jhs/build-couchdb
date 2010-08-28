# Couch servers for users stuff.

require 'tmpdir'

namespace :tracemonkey do

  desc 'Build Tracemonkey'
  task :build => [:known_distro, 'environment:path', JS_LIB]

  file JS_LIB => [package_dep('/usr/bin/python' => 'python'), AUTOCONF_213] do
    src = "#{DEPS}/js_src"
    begin
      Dir.chdir src

      if DISTRO[0] == :solaris
        # Solaris requires a manual fix to the link flags which is crashing ld.
        ed = %w[ 2317 i MOZ_FIX_LINK_PATHS= . w q ]
        sh "echo '#{ed.join "\\n"}' | ed '#{src}/configure.in'"
      end

      if DISTRO[0] == :slf
          sh 'autoconf-2.13'
      else
          sh 'autoconf2.13'
      end

      Dir.mktmpdir 'tracemonkey_build' do |dir|
        Dir.chdir dir do
          cmd = ["#{src}/configure", "--prefix=#{BUILD}", "--without-x"]
          if DISTRO[0] == :solaris
            cmd = [
              "LDFLAGS='-L/opt/csw/gcc4/lib'",
              "CXXFLAGS='-R/opt/csw/gcc4/lib'",
              cmd,
              '--disable-tracejit'
            ].flatten
          end

          sh(cmd.join(' '))
          gmake
          gmake "install"
        end
      end

      record_manifest 'tracemonkey'
    ensure
      Dir.chdir src
      gmake "distclean" if File.exist? "Makefile"
      sh 'git checkout HEAD configure.in'
      sh 'git clean -df .'
    end
  end
end
