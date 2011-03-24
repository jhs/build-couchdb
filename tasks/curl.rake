# libcurl stuff

namespace :curl do

  desc 'Build libcurl'
  task :build => [:known_distro, 'environment:path', CURL_BIN]

  file CURL_BIN do
    source = "#{DEPS}/curl"
    begin
      Dir.chdir(source) do
        sh "./buildconf"
      end

      Dir.mktmpdir 'curl-build' do |dir|
        Dir.chdir dir do
          show_file("config.log") do
            sh(configure_cmd(source, :prefix => :deps))
          end

          gmake
          gmake "install"

          if DISTRO[0] == :osx
            # TODO: Usually OSX needs this. Also CouchDB probably needs an install_name_tool for libcurl now.
          end
        end
      end

      record_manifest 'curl'
    ensure
      Dir.chdir(source) { sh "git ls-files --others --ignored --exclude-standard | xargs rm || true" }
    end
  end

end
