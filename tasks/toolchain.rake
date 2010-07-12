# Build toolchain

namespace :toolchain do

  %w[ 2.13 2.59 ].each do |version|
    label = "AUTOCONF_#{version.gsub /\W/, ''}"
    raise "Woah, why am I bothering to build autoconf #{version}? There is no #{label} constant" unless Object.const_defined? label

    file Object.const_get(label) do
      Dir.mktmpdir "autoconf-#{version}_build" do |dir|
        Dir.chdir dir do
          begin
            makeinfo = File.new("#{RUBY_BUILD}/bin/makeinfo", 'w')
            makeinfo.chmod 0700
            makeinfo.close

            sh "#{DEPS}/autoconf-#{version}/configure --prefix=#{RUBY_BUILD} --program-suffix=#{version}"
            sh 'make'
            sh 'make install'
          ensure
            File.unlink "#{RUBY_BUILD}/bin/makeinfo"
          end
        end
      end
    end
  end

end
