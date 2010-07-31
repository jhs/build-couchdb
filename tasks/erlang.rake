# Erlang-related tasks

require 'pathname'
require 'fileutils'

namespace :erlang do
  desc 'Build Erlang/OTP'
  task :build => [:known_distro, ERL_BIN]

  # Some libraries needn't be compiled. Others can be deleted later.
  OTP_REMOVE = %w[ compiler syntax_tools public_key parsetools ic erts ]
  OTP_SKIP_COMPILE = %w[
    appmon asn1 common_test cosEvent cosEventDomain cosFileTransfer cosNotification cosProperty cosTime cosTransactions
    wx debugger ssh test_server toolbar odbc orber otp_mibs os_mon reltool snmp observer dialyzer docbuilder edoc et
    eunit gs hipe runtime_tools erl_interface percept pman tools inviso tv typer webtool jinterface megaco mnesia
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

        OTP_SKIP_COMPILE.each do |lib|
          FileUtils.touch "#{DEPS}/otp/lib/#{lib}/SKIP"
        end

        sh configure.join(' ')
        sh 'make'
        sh 'make install'

        if [:ubuntu, :debian].include?(DISTRO[0]) && ENV['bind_cap']
          %w[ beam beam.smp ].each do |program|
            path = Pathname.new(ERL_BIN).realpath.parent.parent + 'erts-5.7.5' + 'bin' + program
            sh "sudo setcap cap_net_bind_service=+ep #{path}"
          end
        end
      ensure
        Dir.chdir source
        sh 'git reset --hard && git clean -fd'
        sh "git ls-files --others --ignored --exclude-standard | xargs rm -vf"
      end
    end
  end

  task :clean do
    lib = "'#{BUILD}/lib/erlang/lib'"
    (OTP_REMOVE + OTP_SKIP_COMPILE).each do |component|
      sh "rm -rf #{lib}/#{component}-*"
    end
    sh "find #{lib} -type d -name src -print0 | xargs -0 rm -rf"
    sh "find '#{BUILD}/lib/erlang' -type d -name include -print0 | xargs -0 rm -rf"
  end

end
