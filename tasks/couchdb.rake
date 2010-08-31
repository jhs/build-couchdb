# Building CouchDB

require 'uri'
require 'tmpdir'

namespace :couchdb do

  desc 'Build CouchDB'
  task :build => ['erlang:build', 'build:os_dependencies', 'tracemonkey:build', 'icu:build', :known_distro, 'environment:path', COUCH_BIN]

  desc 'Build CouchDB and then clean out unnecessary things like autotools'
  task :clean_install => :build do
    %w[ erlang toolchain ].each do |section|
      run_task "#{section}:clean"
    end

    %w[ include ].each do |dir|
      FileUtils.rm_rf "#{BUILD}/#{dir}"
    end
  end

  directory "#{BUILD}/var/run/couchdb"

  file COUCH_BIN => [AUTOCONF_259, "#{BUILD}/var/run/couchdb"] do
    source = "#{DEPS}/couchdb"

    if ENV['git']
      remote, commit = ENV['git'].split
      checkout = "#{HERE}/git-build/#{URI.escape(remote, /[\/:]/)}"

      if File.directory?(checkout) || File.symlink?(checkout)
        puts "Using #{checkout} for build from Git"
      elsif File.exists? checkout
        raise "Don't know what to do with #{checkout}"
      else
        sh "git clone '#{remote}' '#{checkout}'"
      end

      Dir.chdir checkout do
        sh "git checkout #{commit}"
        sh "git reset --hard"
        sh "git clean -f -d"
        rm = (DISTRO[0] == :solaris) ? 'rm' : 'rm -v'
        sh "git ls-files --others -i --exclude-standard | xargs #{rm} || true"
      end

      source = checkout
    end

    begin
      Dir.chdir(source) do
        # TODO: Use the built-in autoconf (with_autoconf '2.59') instead of depending on the system.
        cmd = "./bootstrap"
        cmd = "SED=`which sed` #{cmd}" if DISTRO[0] == :solaris
        sh cmd
      end

      Dir.mktmpdir 'couchdb-build' do |dir|
        Dir.chdir dir do
          libs = ["#{BUILD}/lib"]

          if DISTRO[0] == :solaris
            libs += %w[ /opt/csw/lib /opt/csw/gcc4/lib /opt/csw/lib/i386 ]
          end

          ldflags = libs.map{|lib| "-R#{lib} -L#{lib}"}.join(' ')
          ldflags += ' -llber' if DISTRO[0] == :solaris

          env = "LDFLAGS='#{ldflags}' CFLAGS='-I#{BUILD}/include/js'"
          sh "env #{env} #{source}/configure --prefix=#{COUCH_BUILD} --with-erlang=#{BUILD}/lib/erlang/usr/include"

          gmake
          gmake "check" if ENV['make_check']
          gmake "install"

          compress_beams "#{COUCH_BUILD}/lib/couchdb/erlang"

          if DISTRO[0] == :osx
            icu = Dir.glob("#{BUILD}/lib/couchdb/erlang/lib/couch-*/priv/lib/couch_icu_driver.so").last
            js  = "#{BUILD}/lib/couchdb/bin/couchjs"

            sh "install_name_tool -change libicuuc.44.dylib #{BUILD}/lib/libicuuc.44.dylib #{icu}"
            sh "install_name_tool -change libicui18n.44.dylib #{BUILD}/lib/libicui18n.44.dylib #{icu}"
            sh "install_name_tool -change ../lib/libicudata.44.0.dylib #{BUILD}/lib/libicudata.44.0.dylib #{icu}"

            sh "install_name_tool -change @executable_path/libmozjs.dylib #{BUILD}/lib/libmozjs.dylib #{js}"
          end
        end

        record_manifest 'couchdb'
      end
    ensure
      Dir.chdir(source) { sh "git ls-files --others --ignored --exclude-standard | xargs rm -vf" }
    end
  end

end
