# Miscellaneous build tasks

require 'tmpdir'
require 'tempfile'
require 'fileutils'

namespace :build do
  COUCH_BIN = "#{BUILD}/bin/couchdb"

  desc 'Confirm the correct Ruby environment for development and deployment'
  task :confirm_ruby => :os_dependencies do
    expectation = "#{RUBY_BUILD}/bin"
    %w[ ruby gem rake ].each do |cmd|
      raise "#{cmd} not running from #{expectation}. Did you source env.sh?" unless `which #{cmd}`.chomp.match(Regexp.new "#{expectation}/#{cmd}$")
    end
  end

  desc 'Hook into the Ruby in a Box environment to get everything else built and installed'
  task :ruby_inabox => :couchdb

  desc 'Build CouchDB'
  task :couchdb => ['erlang:build', :os_dependencies, 'tracemonkey:build', 'icu:build', COUCH_BIN] do
    # After everything is installed, Erlang can be stripped.
    Rake::Task['erlang:clean'].reenable
    Rake::Task['erlang:clean'].invoke
  end

  directory "#{BUILD}/var/run/couchdb"

  file COUCH_BIN => [AUTOCONF_259, "#{BUILD}/var/run/couchdb", 'environment:path'] do
    source = "#{DEPS}/couchdb"
    begin
      Dir.chdir(source) { sh "./bootstrap" } # TODO: Use the built-in autoconf (with_autoconf '2.59') instead of depending on the system.

      Dir.mktmpdir 'couchdb-build' do |dir|
        Dir.chdir dir do
          env = { :ubuntu => "LDFLAGS='-R#{BUILD}/lib -L#{BUILD}/lib' CFLAGS='-I#{BUILD}/include/js'",
                  :debian => "LDFLAGS='-R#{BUILD}/lib -L#{BUILD}/lib' CFLAGS='-I#{BUILD}/include/js'",
                  :osx    => "LDFLAGS='-R#{BUILD}/lib -L#{BUILD}/lib' CFLAGS='-I#{BUILD}/include/js'",
                }.fetch DISTRO[0], ''
          sh "env #{env} #{source}/configure --prefix=#{BUILD} --with-erlang=#{BUILD}/lib/erlang/usr/include"
          sh "make"
          sh "make check"
          sh 'make install'

          if DISTRO[0] == :osx
            icu = Dir.glob("#{BUILD}/lib/couchdb/erlang/lib/couch-*/priv/lib/couch_icu_driver.so").last
            js  = "#{BUILD}/lib/couchdb/bin/couchjs"

            sh "install_name_tool -change libicuuc.44.dylib #{BUILD}/lib/libicuuc.44.dylib #{icu}"
            sh "install_name_tool -change libicui18n.44.dylib #{BUILD}/lib/libicui18n.44.dylib #{icu}"
            sh "install_name_tool -change ../lib/libicudata.44.0.dylib #{BUILD}/lib/libicudata.44.0.dylib #{icu}"

            sh "install_name_tool -change @executable_path/libmozjs.dylib #{BUILD}/lib/libmozjs.dylib #{js}"
          end
        end
      end
    ensure
      Dir.chdir(source) { sh "git ls-files --others --ignored --exclude-standard | xargs rm -vf" }
    end
  end

  desc 'Confirm (and install if possible) the OS dependencies'
  task :os_dependencies => [:mac_dependencies, :ubuntu_dependencies, :debian_dependencies]

  task :debian_dependencies => :known_distro do
    if DISTRO[0] == :debian
      install [
        # For building OTP
        %w[ quilt unixodbc-dev flex dctrl-tools libsctp-dev libgl1-mesa-dev libglu1-mesa-dev ],

        # All Ubuntu gets these.
        %w[ libxslt1-dev automake help2man libcurl4-openssl-dev libreadline5-dev make bison ruby libtool g++ ],
        %w[ zip libcap2-bin ],

        # Needed for Varnish
        %w[ libpcre3-dev ]
      ].flatten
    end
  end

  task :ubuntu_dependencies => :known_distro do
    if DISTRO[0] == :ubuntu
      # For building OTP
      install %w[ quilt unixodbc-dev flex dctrl-tools libsctp-dev libgl1-mesa-dev libglu1-mesa-dev ]

      # All Ubuntu gets these.
      install %w[ libxslt1-dev automake help2man libcurl4-openssl-dev libreadline5-dev make bison ruby libtool g++ ]
      install %w[ zip libcap2-bin ]

      # Needed for Varnish
      #install %w[ libpcre3-dev ]
    end
  end

  task :mac_dependencies => :known_distro do
    %w[ gcc make ].each do |dep|
      raise 'Please install Xcode from Apple' if DISTRO[0] == :osx and system("#{dep} --version > /dev/null 2> /dev/null") == false
    end
  end

  #desc 'Completely uninstall everything except source'
  #task :distclean => :clean do
  #  sh "rm -rf #{RUBY_BUILD}"
  #end

  desc 'Clean all CouchDB-related build output'
  task :clean do
    sh "rm -rf #{BUILD}"
  end

end
