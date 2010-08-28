# Erlang-related tasks

require 'pathname'
require 'fileutils'

namespace :erlang do
  desc 'Build Erlang/OTP'
  task :build => [:known_distro, 'build:os_dependencies', 'environment:path', ERL_BIN]

  # Some libraries needn't be compiled. Others can be deleted later.
  OTP_REMOVE = %w[ compiler syntax_tools public_key parsetools ic erts erl_interface eunit ]
  OTP_SKIP_COMPILE = %w[
    appmon asn1 common_test cosEvent cosEventDomain cosFileTransfer cosNotification cosProperty cosTime cosTransactions
    wx debugger ssh test_server toolbar odbc orber otp_mibs os_mon reltool snmp observer dialyzer docbuilder edoc et
    gs hipe runtime_tools percept pman tools inviso tv typer webtool jinterface megaco mnesia
  ]

  file ERL_BIN => AUTOCONF_259 do
    source = "#{DEPS}/otp"
    Dir.chdir source
    with_autoconf '2.59' do
      begin
        sh './otp_build autoconf'

        cflags = '-g -O2 -fno-strict-aliasing'
        ldflags = ''
        if DISTRO[0] == :solaris
          cflags += ' -I/opt/csw/include -L/opt/csw/lib'
          ldflags = '-L/opt/csw/lib'
        end

        configure = [
          "CFLAGS='#{cflags}'",
          "LDFLAGS='#{ldflags}'",
          './configure',
          "--prefix=#{BUILD}",
          "--without-javac",
          "--without-termcap",
          "--enable-shared-zlib",
          '--enable-smp-support',
          '--enable-hybrid-heap',
          '--enable-threads',
          '--disable-hipe',
          '--enable-kernel-poll',
          DISTRO[0] != :solaris ? '--enable-sctp' : '',
          "--with-ssl",
          '--enable-dynamic-ssl-lib',
        ]
        case DISTRO[0]
          when :ubuntu, :debian
            configure.push '--enable-clock-gettime'
            configure.push '--host=x86_64-linux-gnu', '--build=x86_64-linux-gnu' if DISTRO[1] == '9.10'
          when :osx
            configure.push '--enable-darwin-64bit' if DISTRO[0] == :osx
          when :solaris
            configure.insert(0, 'CC=gcc')
            configure.insert(0, 'LD=gld')
        end

        otp_keep = ENV['otp_keep'] || ''
        OTP_SKIP_COMPILE.each do |lib|
          FileUtils.touch "#{DEPS}/otp/lib/#{lib}/SKIP" unless otp_keep == '*' || otp_keep.split.include?(lib)
        end

        sh configure.join(' ')
        gmake
        gmake "install"

        # Cleanup. Much thanks to the Fedora 13 source RPM!
        erlang = "#{BUILD}/lib/erlang"
        Find.find(erlang) do |path|
          if File.directory?(path) && (File.stat(path).mode & 000775 == 0775)
            FileUtils.chmod 0755, path
          end
        end
        sh "rm -rf #{erlang}/misc"
        compress_beams erlang

      ensure
        Dir.chdir source
        sh 'git reset --hard && git clean -fd'
        rm = (DISTRO[0] == :solaris) ? 'rm' : 'rm -v'
        sh "git ls-files --others -i --exclude-standard | xargs #{rm} || true"
      end
    end

    record_manifest 'erlang'
  end

  task :clean do
    erlang = "'#{BUILD}'/lib/erlang"
    lib = "#{erlang}/lib"

    otp_keep = ENV['otp_keep'] || ''
    (OTP_REMOVE + OTP_SKIP_COMPILE).each do |component|
      sh "rm -rf #{lib}/#{component}-*" unless otp_keep == '*' || otp_keep.split.include?(component)
    end

    # Remove unnecessary directories for running.
    %w[ src examples include doc man obj erl_docgen-* misc ].each do |dir|
      Find.find(erlang) do |path|
        sh "rm -rf '#{dir}'" if File.directory?(path) && File.basename(path) == dir
      end
    end

    sh "rm #{erlang}/Install"
  end

end
