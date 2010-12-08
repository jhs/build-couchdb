# Building CouchDB

require 'uri'
require 'tmpdir'
require 'fileutils'

namespace :couchdb do

  couchdb_build_deps = ['erlang:build', 'build:couch_git_submodules', 'build:os_dependencies', 'tracemonkey:build', 'icu:build', :known_distro, 'environment:path']

  desc 'Build the requirements for CouchDB'
  task :deps => couchdb_build_deps
  task :dependencies => :deps

  desc 'Build CouchDB'
  task :build => [:couchdb, :plugins, 'environment:install']

  task :couchdb => couchdb_build_deps + [COUCH_BIN]

  desc 'Build CouchDB and then clean out unnecessary things like autotools'
  task :clean_install => :build do
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

  file COUCH_BIN => [COUCH_SOURCE + '/.git', AUTOCONF_259, "#{BUILD}/var/run/couchdb"] do
    source = COUCH_SOURCE

    begin
      Dir.chdir(source) do
        # TODO: Use the built-in autoconf (with_autoconf '2.59') instead of depending on the system.
        cmd = "./bootstrap"
        cmd = "SED=`which sed` #{cmd}" if DISTRO[0] == :solaris
        sh cmd
      end

      Dir.mktmpdir 'couchdb-build' do |dir|
        Dir.chdir dir do
          show_file("config.log") do
            sh(configure_cmd(source, :prefix => true))
          end

          gmake
          gmake "check" if ENV['make_check']
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
      Dir.chdir(source) { sh "git ls-files --others --ignored --exclude-standard | xargs rm -vf" }
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
      plugin_mark = "#{COUCH_BUILD}/lib/couchdb/plugins/#{git_checkout_name(remote + ':' + commit)}"
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
          begin
            ENV['ERL_COMPILER_OPTIONS'] = "[{i, \"#{COUCH_SOURCE}/src/couchdb\"}]"
            sh "./rebar clean"
            sh "./rebar compile"
          ensure
            ENV.delete('ERL_COMPILER_OPTIONS')
          end
        else
          raise "I do not know how to build this plugin: #{source}"
        end

        target = plugin_mark + '_new'
        FileUtils.mkdir_p(target)

        cp = (DISTRO[0] == :solaris) ? 'cp' : 'cp -v'
        %w[ build ebin ].each do |ebin|
          sh "#{cp} -r #{ebin}/*.beam '#{target}'" if File.directory?(ebin)
        end

        sh "mv #{target} #{plugin_mark}"

        copy_parts :source => ".", :target => BUILD, :dirs => %w[ etc bin lib var ]

        # Futon stuff can only run from the actual couch location, unfortunately.
        sh "cp -v share/www/script/test/* '#{COUCH_BUILD}/share/couchdb/www/script/test'" if File.directory? "share/www"
      end
    end
  end

end
