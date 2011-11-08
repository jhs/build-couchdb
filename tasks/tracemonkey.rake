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

          cmd = ["CC=gcc", "CXX=g++", cmd].flatten if DISTRO[0] == :osx

          show_file('config.log') do
            sh(["env", cmd].flatten.join(' '))
          end

          gmake
          gmake "install"

          # The CouchDB 1.1.1 configure script first tries to link against "libmozjs185" before trying "libmozjs".
          # Unfortunately, Ubuntu 11.04 installs /usr/lib/libmozjs185.so, so despite all those -Ls and -Rs, the first
          # test succeeds, causing Couch to use the system libmozjs, which is bad. I investigated several ideas:
          #
          # 1. ./configure --program-suffix=185, to build a libmozjs185.so, but that, firstly, didn't even work,
          #    and secondly, would probably cause trouble with CouchDB 1.1.0 which still wants libmozjs.so.
          # 2. Various -nostdlib and -nostartfiles options in LDFLAGS, to prevent it from searching /usr/lib. That
          #    broke linking against libc, libgcc, libm, etc. and even if it could be done right, it seems brittle.
          # 3. Just symlink it so ld finds what it wants. And that worked.
          sh "ln", "-sf", "libmozjs.so", "#{BUILD}/lib/libmozjs185.so" unless DISTRO[0] == :osx
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
