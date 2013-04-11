# Build toolchain

require 'tmpdir'
require 'fileutils'

namespace :toolchain do

  autotools_versions = %w[ 2.13 2.59 2.62 2.69 ]
  autotools_versions.each do |version|
    label = "AUTOCONF_#{version.gsub(/\W/, '')}"
    raise "Woah, why am I bothering to build autoconf #{version}? There is no #{label} constant" unless Object.const_defined? label

    autoconf_src = "#{DEPS}/autoconf-#{version}"
    packages = [ package_dep('/opt/csw/bin/gm4'  => 'gm4', :distros => [:solaris]),
                 package_dep('/opt/csw/bin/gsed' => 'gsed', :distros => [:solaris])
               ]

    file Object.const_get(label) => packages do |task|
      Rake::Task['environment:path'].invoke

      Dir.mktmpdir "autoconf-#{version}_build" do |dir|
        Dir.chdir dir do
          begin
              if ! File.file? "#{autoconf_src}/configure"
                #puts "Must autoreconf -i"
                Dir.chdir autoconf_src do
                  #sh "bash"
                  sh "autoreconf", "-i"
                end
              end

              show_file('config.log') do
                datadir = %w[ 2.13 2.59 ].include?(version) ? "datadir" : "datarootdir"
                sh "#{autoconf_src}/configure", "--prefix=#{BUILD}", "--program-suffix=#{version}",
                   "--#{datadir}=#{BUILD}/share/autoconf-#{version}"
              end

              gmake
              gmake "install"
              record_manifest task.name
          ensure
            # Clean the git code.
            Dir.chdir autoconf_src do
              sh "git", "checkout", "HEAD", "."
              sh "rm", "-rf", "autom4te.cache"
            end
          end
        end
      end
    end
  end

  file LIBTOOL => AUTOCONF_262 do |task|
    Rake::Task['environment:path'].invoke

    with_autoconf "2.62" do
      git_work LIBTOOL_SOURCE do
        sh "./bootstrap"

        show_file('config.log') do
          sh "#{LIBTOOL_SOURCE}/configure", "--prefix=#{BUILD}"
        end

        gmake
        gmake "install"

        record_manifest task.name
      end # git_work LIBTOOL_SOURCE
    end # with_autoconf
  end

  file AUTOMAKE => LIBTOOL do |task|
    Rake::Task['environment:path'].invoke

    # Automake needs a ./bootstrap, and then needs to be cleaned up afterward.
    with_autoconf "2.62" do
      Dir.chdir AUTOMAKE_SOURCE do
        begin
          sh "./bootstrap"

          # Now automake can be built.
          Dir.mktmpdir "automake_build" do |build_dir|
            Dir.chdir build_dir do
              show_file('config.log') do
                sh "#{AUTOMAKE_SOURCE}/configure", "--prefix=#{BUILD}"
              end

              gmake
              gmake "install"
              record_manifest task.name
            end
          end # mktmpdir "automake_build"
        ensure
          if Dir.pwd != AUTOMAKE_SOURCE
            puts "WARNING: Failed to reset files: #{AUTOMAKE_SOURCE}"
          else
            puts "Resetting changes automake made to itself: #{AUTOMAKE_SOURCE}"
            sh "git", "checkout", "HEAD", "."
            FileUtils.rm_rf "autom4te.cache"
          end
        end
      end # chdir AUTOMAKE_SOURCE
    end # with_autoconf
  end

  file AUTOCONF_ARCHIVE => [AUTOMAKE, AUTOCONF_269] do |task|
    Rake::Task['environment:path'].invoke

    py_version = `python --version 2>&1`
    is_old_python = py_version.match /2\.[0-6]/

    # Gnulib must be in the path to build this.
    with_path "#{DEPS}/gnulib" do
      with_autoconf "2.69" do
        git_work AUTOCONF_ARCHIVE_SOURCE do
          if DISTRO[0] == :osx
            sh "sed", "-i.build-couchdb", "-e", "s/sed -i/sed -i.build-couchdb/", "bootstrap.sh"
            sh "sed", "-i.build-couchdb", "-e", "s/echo/\\/bin\\/echo/"         , "configure.ac"
          end

          if is_old_python
            raise StandardError, "Cannot build with old Python"
          end

          sh "./bootstrap.sh"

          show_file('config.log') do
            sh "./configure", "--prefix=#{BUILD}"
          end

          with_fakes 'makeinfo', 'help2man' do
            gmake "maintainer-all"
            gmake
            gmake "install"

            # Just copy the pkg.m4 that comes with Spidermonkey for now.
            sh "cp", "#{DEPS}/spidermonkey/js/src/build/autoconf/pkg.m4", "#{BUILD}/share/aclocal/pkg.m4"
          end

          record_manifest task.name
          puts "Manifest: #{task.name.inspect}"
        end # git_work AUTOCONF_ARCHIVE_SOURCE
      end # with_autoconf "2.69"
    end # with_path "DEPS/gnulib"
  end

  task :clean do
    %w[ info share/emacs share/autoconf ].each do |dir|
      FileUtils.rm_rf "#{BUILD}/#{dir}"
    end

    autotools_versions.each do |ver|
      Dir.glob("#{BUILD}/bin/*#{ver}").each { |file| FileUtils.rm_f file }
    end
  end

end
