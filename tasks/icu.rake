# libicu

namespace :icu do

  desc 'Build libicu'
  task :build => [:known_distro, ICU_BIN]

  file ICU_BIN do
    src = "#{DEPS}/icu4c-4_4/source"
    Dir.mktmpdir "icu_build" do |dir|
      begin
        Dir.chdir dir do
          sh "#{src}/configure --prefix=#{BUILD}"
          sh 'make'
          sh 'make install'

          if DISTRO[0] == :osx
            sh "install_name_tool -change libicudata.44.dylib #{BUILD}/lib/libicudata.44.dylib #{BUILD}/lib/libicuuc.44.dylib"
            sh "install_name_tool -change libicudata.44.dylib #{BUILD}/lib/libicudata.44.dylib #{BUILD}/lib/libicui18n.44.dylib"
            sh "install_name_tool -change libicuuc.44.dylib #{BUILD}/lib/libicuuc.44.dylib #{BUILD}/lib/libicui18n.44.dylib"
          end
        end
      ensure
        Dir.chdir(src) { sh 'make distclean' if File.exist? 'Makefile' }
      end
    end
  end

end
