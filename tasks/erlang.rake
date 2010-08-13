# Erlang-related tasks

require 'pathname'
require 'fileutils'

namespace :erlang do
  desc 'Build Erlang/OTP'
  task :build => [:known_distro, ERL_BIN]

  # Some libraries needn't be compiled. Others can be deleted later.
  OTP_REMOVE = %w[ compiler syntax_tools public_key parsetools ic erts erl_interface ]
  OTP_SKIP_COMPILE = %w[
    appmon asn1 common_test cosEvent cosEventDomain cosFileTransfer cosNotification cosProperty cosTime cosTransactions
    wx debugger ssh test_server toolbar odbc orber otp_mibs os_mon reltool snmp observer dialyzer docbuilder edoc et
    eunit gs hipe runtime_tools percept pman tools inviso tv typer webtool jinterface megaco mnesia
  ]

  file ERL_BIN => AUTOCONF_259 do
    source = "#{DEPS}/otp"
    Dir.chdir source
    with_autoconf '2.59' do
      begin
        sh './otp_build autoconf'

        configure = [
          "CFLAGS='-g -O2 -fno-strict-aliasing'",
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
          '--enable-sctp',
          "--with-ssl",
          '--enable-dynamic-ssl-lib',
        ]
        if [:ubuntu, :debian].include? DISTRO[0]
          configure.push '--enable-clock-gettime'
          configure.push '--host=x86_64-linux-gnu', '--build=x86_64-linux-gnu' if DISTRO[1] == '9.10'
        end
        configure.push '--enable-darwin-64bit' if DISTRO[0] == :osx

        otp_keep = ENV['otp_keep'] || ''
        OTP_SKIP_COMPILE.each do |lib|
          FileUtils.touch "#{DEPS}/otp/lib/#{lib}/SKIP" unless otp_keep == '*' || otp_keep.split.include?(lib)
        end

        sh configure.join(' ')
        sh 'make'
        sh 'make install'

        # Cleanup. Much thanks to the Fedora 13 source RPM!
        erlang = "#{BUILD}/lib/erlang"
        sh "find #{erlang} -type d -perm 0775 -print0 | xargs -0 chmod 0755"
        sh "rm -rf #{erlang}/misc"
        compress_beams erlang

      ensure
        Dir.chdir source
        sh 'git reset --hard && git clean -fd'
        sh "git ls-files --others --ignored --exclude-standard | xargs rm -vf"
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
      sh "find #{erlang} -type d -name '#{dir}' -print0 | xargs -0 rm -rf"
    end

    sh "rm #{erlang}/Install"
  end

end
