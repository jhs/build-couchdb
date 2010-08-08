# Building CouchDB
require 'uri'

namespace :couchdb do

  desc 'Build CouchDB'
  task :build => ['erlang:build', 'build:os_dependencies', 'tracemonkey:build', 'icu:build', COUCH_BIN]

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

  file COUCH_BIN => [AUTOCONF_259, "#{BUILD}/var/run/couchdb", 'environment:path'] do
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
        sh "git ls-files --others -i --exclude-standard | xargs rm -v || true"
      end

      source = checkout
    end

    begin
      Dir.chdir(source) { sh "./bootstrap" } # TODO: Use the built-in autoconf (with_autoconf '2.59') instead of depending on the system.

      Dir.mktmpdir 'couchdb-build' do |dir|
        Dir.chdir dir do
          env = { :ubuntu => "LDFLAGS='-R#{BUILD}/lib -L#{BUILD}/lib' CFLAGS='-I#{BUILD}/include/js'",
                  :debian => "LDFLAGS='-R#{BUILD}/lib -L#{BUILD}/lib' CFLAGS='-I#{BUILD}/include/js'",
                  :fedora => "LDFLAGS='-R#{BUILD}/lib -L#{BUILD}/lib' CFLAGS='-I#{BUILD}/include/js'",
                  :osx    => "LDFLAGS='-R#{BUILD}/lib -L#{BUILD}/lib' CFLAGS='-I#{BUILD}/include/js'",
                }.fetch DISTRO[0], ''
          sh "env #{env} #{source}/configure --prefix=#{COUCH_BUILD} --with-erlang=#{BUILD}/lib/erlang/usr/include"
          sh "make"
          sh "make check" if ENV['make_check']
          sh 'make install'

          compress_beams "#{BUILD}/lib/couchdb/erlang"

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
