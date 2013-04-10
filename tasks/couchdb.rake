# Building CouchDB

require 'uri'
require 'tmpdir'
require 'fileutils'

namespace :couchdb do

  couchdb_build_deps = ['erlang:build', 'build:couch_git_submodules', 'build:os_dependencies', 'tracemonkey:build', 'icu:build', 'curl:build', :known_distro, 'environment:path']

  desc 'Build the requirements for CouchDB'
  task :deps => couchdb_build_deps
  task :dependencies => :deps

  desc 'Build CouchDB'
  task :build => [:couchdb, :plugins, 'environment:install']

  task :couchdb => couchdb_build_deps + [COUCH_BIN]

  desc 'Build CouchDB and then clean out unnecessary things like autotools'
  task :clean_install => :build do
    if ENV['wipe_otp_keep']
      puts "Clearing otp_keep for :clean_install"
      ENV.delete("otp_keep")
    end

    %w[ erlang toolchain ].each do |section|
      run_task "#{section}:clean"
    end

    %w[ include ].each do |dir|
      FileUtils.rm_rf "#{BUILD}/#{dir}"
    end
  end

  file (COUCH_SOURCE + '/.git') do
    if ENV['git']
      begin
        git_checkout(ENV['git'])
      rescue
        checkout = git_checkout(ENV['git'], :noop => true)
        puts "Cleaning checkout: #{checkout}"
        sh "rm -rf '#{checkout}'"
      end
    end
  end

  task :plugins do
    # This task will be assigned dependencies dynamically, see the "plugins" stuff below.
    puts "Plugins done"
  end

  directory "#{BUILD}/var/run/couchdb"

  file COUCH_BIN => [COUCH_SOURCE + '/.git', AUTOCONF_269, AUTOMAKE, AUTOCONF_ARCHIVE, "#{BUILD}/var/run/couchdb"] do
    source = COUCH_SOURCE

    begin
      Dir.chdir(source) do
        cmd = "./bootstrap"
        cmd = "SED=`which sed` #{cmd}" if DISTRO[0] == :solaris

        with_autoconf "2.69" do
          sh cmd
        end

        # GCC 4.1.2 from RHEL and CentOS 5 rejects utf8.h due to a missing final newline.
        if File.exists? "src/couchdb/priv/couch_js/utf8.h"
          utf8_h = File.new("src/couchdb/priv/couch_js/utf8.h", "a")
          utf8_h.write("\n")
          utf8_h.close
        end
      end

      Dir.mktmpdir 'couchdb-build' do |dir|
        Dir.chdir dir do
          show_file("config.log") do
            sh(configure_cmd(source, :prefix => :couch))
          end

          gmake
          gmake "check" if ENV['make_check']

          # Build Fauxton if possible.
          fauxton_src = "#{source}/src/fauxton"
          if File.directory?(fauxton_src) && ENV['skip_fauxton'].nil?
            Dir.chdir fauxton_src do
              sh "npm", "install"
              sh "./node_modules/.bin/grunt", "couchdb"
            end
          end

          gmake "install"

          compress_beams "#{COUCH_BUILD}/lib/couchdb/erlang"

          if DISTRO[0] == :osx
            icu = Dir.glob("#{COUCH_BUILD}/lib/couchdb/erlang/lib/couch-*/priv/lib/couch_icu_driver.so").last
            js  = "#{COUCH_BUILD}/lib/couchdb/bin/couchjs"

            sh "install_name_tool -change libicuuc.44.dylib #{BUILD}/lib/libicuuc.44.dylib #{icu}"
            sh "install_name_tool -change libicui18n.44.dylib #{BUILD}/lib/libicui18n.44.dylib #{icu}"
            sh "install_name_tool -change ../lib/libicudata.44.0.dylib #{BUILD}/lib/libicudata.44.0.dylib #{icu}"

            sh "install_name_tool -change @executable_path/libmozjs.dylib #{BUILD}/lib/libmozjs.dylib #{js}"
          end
        end

        record_manifest 'couchdb'
      end
    ensure
      Dir.chdir(source) do
        sh "git", "checkout", "HEAD", "src/couchdb/priv/couch_js/utf8.h" if File.exists? "src/couchdb/priv/couch_js/utf8.h"
        sh "git ls-files --others --ignored --exclude-standard | xargs rm -vf"
      end
    end
  end

  # Determine what plugins are desired and have them built.
  plugins = (ENV['plugin'] || "") + "," + (ENV['plugins'] || "")
  plugins = plugins.split(',').map{|x| x.strip}.select{|x| ! x.empty? }

  unless plugins.empty?
    puts "Setting otp_keep=\"*\" for building plugins"
    ENV['otp_keep'] = '*'
  end

  plugins.each do |plugin_path|
    #puts "plugin_path #{plugin_path.inspect}"
    git_url = /^git[@:].* /
    if plugin_path.match(git_url)
      remote, commit = plugin_path.split
      # It seems that, If a plugin is an OTP application, it must be in a directory of the application name.
      # Therefore instead of a full Git URL as the mark, just use the base name.
      plugin_mark = "#{COUCH_BUILD}/lib/couchdb/plugins/#{File.basename(remote)}"
      source = git_checkout(plugin_path, :noop => true)
    else
      plugin_mark = "#{COUCH_BUILD}/lib/couchdb/plugins/#{File.basename plugin_path}"
      source = plugin_path
    end
    #puts "plugin_mark: #{plugin_mark.inspect}"

    # The plugin build will depend on the source code being there and tidy.
    puts "Making file task: #{source}"
    file source do
      begin
        git_checkout(plugin_path) if plugin_path.match(git_url)
      ensure
        raise "Could not find plugin: #{plugin_path}" unless File.directory?("#{source}/src")
      end
    end

    task :plugins => ['environment:path', plugin_mark]
    puts "file #{plugin_mark} => #{source}"
    file plugin_mark => ['environment:path', source, :known_distro, :couchdb] do
      puts "Building plugin in: #{source}"
      Dir.chdir(source) do
        if File.exists? 'Makefile'
          gmake "COUCH_SRC='#{COUCH_SOURCE}/src/couchdb' clean"
          gmake "COUCH_SRC='#{COUCH_SOURCE}/src/couchdb'"
        elsif File.exists? 'rebar'
          make_script = false
          begin
            if File.exists?("rebar.config") && !File.exists?("rebar.config.script")
              make_script = true
              ENV['COUCHDB_DEP'] = "#{COUCH_BUILD}/lib/couchdb/erlang/lib"
              sh "cp", "-n", "#{HERE}/lib/templates/rebar.config.script", "." # noclobber
            else
              ENV['ERL_COMPILER_OPTIONS'] = "[{i, \"#{COUCH_SOURCE}/src/couchdb\"}]"
            end

            sh "./rebar clean"
            sh "./rebar get-deps" unless ENV['skip_deps']
            sh "./rebar compile"
          ensure
            ENV.delete('ERL_COMPILER_OPTIONS')
            ENV.delete('COUCHDB_DEP')
            sh "rm", "-f", "rebar.config.script" if make_script
          end
        else
          raise "I do not know how to build this plugin: #{source}"
        end

        target = plugin_mark + '_new'
        FileUtils.mkdir_p(target)

        copy_parts :source => ".", :target => target, :dirs => %w[ ebin priv ]

        # Manually copy "build/" to support GeoCouch.
        if File.directory?('build')
          FileUtils.mkdir_p("#{target}/ebin")
          cp = (DISTRO[0] == :solaris) ? 'cp' : 'cp -v'
          sh "#{cp} -r build/* '#{target}/ebin'" if File.directory?('build')
        end

        sh "mv #{target} #{plugin_mark}"

        copy_parts :source => ".", :target => COUCH_BUILD, :dirs => %w[ etc bin lib var ]

        # Futon stuff can only run from the actual couch location, unfortunately.
        sh "cp -v share/www/script/test/* '#{COUCH_BUILD}/share/couchdb/www/script/test'" if File.directory? "share/www"
      end
    end
  end

  desc 'Run ./configure in a CouchDB checkout'
  task :configure => [:known_distro, 'environment:path', 'couchdb:dependencies', AUTOCONF_269, AUTOCONF_ARCHIVE] do
    nocouch = "This task must run in a normal CouchDB checkout or tarball"
    raise nocouch unless File.directory?('src/couchdb')

    unless File.file? 'configure'
      with_autoconf "2.69" do
        sh "./bootstrap"
      end
    end

    if DISTRO[0] == :osx
      ENV['DYLD_LIBRARY_PATH'] = "#{BUILD}/lib" + (ENV['DYLD_LIBRARY_PATH'] ? ":#{ENV['DYLD_LIBRARY_PATH']}" : "")
      puts "DYLD_LIBRARY_PATH=#{ENV['DYLD_LIBRARY_PATH']}"
    end

    cmd = configure_cmd '.', :prefix => nil
    sh cmd
  end

end
