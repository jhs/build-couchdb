# Build toolchain

require 'fileutils'

namespace :toolchain do

  autotools_versions = %w[ 2.13 2.59 ]

  autotools_versions.each do |version|
    label = "AUTOCONF_#{version.gsub /\W/, ''}"
    raise "Woah, why am I bothering to build autoconf #{version}? There is no #{label} constant" unless Object.const_defined? label

    file Object.const_get(label) => 'environment:path' do
      Dir.mktmpdir "autoconf-#{version}_build" do |dir|
        Dir.chdir dir do
          begin
            makeinfo = File.new("#{BUILD}/bin/makeinfo", 'w')
            makeinfo.chmod 0700
            makeinfo.close

            sh "#{DEPS}/autoconf-#{version}/configure --prefix=#{BUILD} --program-suffix=#{version}"
            sh 'make'
            sh 'make install'
          ensure
            File.unlink "#{BUILD}/bin/makeinfo" if File.exist? "#{BUILD}/bin/makeinfo"
          end
        end
      end
    end
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
