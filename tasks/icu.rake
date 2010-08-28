# libicu

require 'tmpdir'

namespace :icu do

  desc 'Build libicu'
  task :build => [:known_distro, 'environment:path', ICU_BIN]

  file ICU_BIN do
    src = "#{DEPS}/icu4c-4_4/source"
    Dir.mktmpdir "icu_build" do |dir|
      begin
        Dir.chdir dir do
          flags = nil

          if DISTRO[0] == :solaris
            libs = ['/opt/csw/lib', '/opt/csw/gcc4/lib', "#{BUILD}/lib"]
            ldflags = libs.map{|lib| "-R#{lib} -L#{lib}"}.join(' ')
            flags = "LDFLAGS='#{ldflags}' CXXFLAGS='-R/opt/csw/gcc4/lib'"
          end

          configure = "#{src}/configure --prefix='#{BUILD}'"
          configure = "#{flags} #{configure}" if flags

          sh "#{configure}"
          gmake
          gmake "install"

          if DISTRO[0] == :osx
            sh "install_name_tool -change libicudata.44.dylib #{BUILD}/lib/libicudata.44.dylib #{BUILD}/lib/libicuuc.44.dylib"
            sh "install_name_tool -change libicudata.44.dylib #{BUILD}/lib/libicudata.44.dylib #{BUILD}/lib/libicui18n.44.dylib"
            sh "install_name_tool -change libicuuc.44.dylib #{BUILD}/lib/libicuuc.44.dylib #{BUILD}/lib/libicui18n.44.dylib"
          end
        end

        record_manifest 'icu'
      ensure
        Dir.chdir(src) { gmake "distclean" if File.exist? 'Makefile' }
      end
    end
  end

end
