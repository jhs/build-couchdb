# Erlang-related tasks

require 'pathname'
require 'fileutils'

namespace :erlang do
  desc 'Build Erlang/OTP'
  task :build => [:known_distro, 'build:otp_git_submodules', 'build:os_dependencies', 'environment:path', ERL_BIN, 'environment:install']

  # Some libraries needn't be compiled. Others can be deleted later. Note the others for completeness.
  OTP_GOOD   = %w[ crypto inets kernel os_mon public_key sasl ssl stdlib xmerl ]
  OTP_REMOVE = %w[ compiler syntax_tools parsetools ic erts erl_interface eunit ]
  OTP_SKIP_COMPILE = %w[
    appmon asn1 common_test cosEvent cosEventDomain cosFileTransfer cosNotification cosProperty cosTime cosTransactions
    wx debugger ssh test_server toolbar odbc orber reltool observer dialyzer docbuilder edoc et
    gs hipe runtime_tools percept pman tools inviso tv typer webtool jinterface megaco mnesia
    diameter erl_docgen
  ]

  # TODO: When Couch version detection exists, only build os_mon for 1.2 and later.
  if true
    # CouchDB 1.2 requires os_mon but not snmp.
    OTP_REMOVE << "snmp"
    OTP_REMOVE << "otp_mibs"
  else
    # Before CouchDB 1.2, these can be skipped altogether.
    OTP_SKIP_COMPILE << "snmp"
    OTP_SKIP_COMPILE << "os_mon"
    OTP_SKIP_COMPILE << "otp_mibs"
  end

  file ERL_BIN => AUTOCONF_259 do
    source = "#{DEPS}/otp"
    Dir.chdir source
    sh('git', 'checkout', ENV['erl_checkout']) if ENV['erl_checkout']
    with_autoconf '2.59' do
      begin
        sh './otp_build autoconf'

        optimization_level = 2
        if DISTRO[0] == :osx
          # Lion uses LLVM and will requires -O0. Sorry, Lion.
          os_release = `sysctl -n kern.osrelease`.chomp
          optimization_level = 0 if /^11\.\d+\./.match(os_release) # 11.*
        end

        cflags = "-g -O#{optimization_level} -fno-strict-aliasing"
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
          "--enable-shared-zlib",
          '--enable-smp-support',
          '--enable-hybrid-heap',
          '--enable-threads',
          '--disable-hipe',
          '--enable-kernel-poll',
          '--disable-sctp',
          "--with-ssl",
          '--enable-dynamic-ssl-lib',
        ]

        configure << (ENV['erl_termcap'] ? '--with-termcap' : '--without-termcap')

        case DISTRO[0]
          when :ubuntu, :debian
            configure.push '--enable-clock-gettime'
            configure.push '--host=x86_64-linux-gnu', '--build=x86_64-linux-gnu' if DISTRO[1] == '9.10'
            machine_hw = %x[ /bin/uname -m ].chomp
            configure << '--enable-m64-build' if $?.success? && machine_hw == 'x86_64'
          when :osx
            is_darwin_64bit = %x[ /usr/sbin/sysctl -n hw.optional.x86_64 2>/dev/null ].chomp
            if $?.success? && is_darwin_64bit == "1"
              configure << '--enable-darwin-64bit'
              configure << '--enable-m64-build'
            end
          when :solaris
            configure.insert(0, 'CC=gcc')
            configure.insert(0, 'LD=gld')
        end

        if ENV['ethread_p4']
          # Described in http://erlang.2086793.n4.nabble.com/R14B-Illegal-instruction-tt2544273.html#a2544362
          configure.push '--enable-ethread-pre-pentium4-compatibility'
          configure.push '--enable-ethread-pre-pentium4-compatibility=yes'
        end

        OTP_SKIP_COMPILE.each do |lib|
          skip_otp_app(lib) unless otp_app_useful?(lib)
        end

        erlang_confopts = ENV['erlang_confopts'] || ""
        raise "Sorry, OS X cannot use --enable-halfword-emulator" \
          if DISTRO[0] == :osx && erlang_confopts.split.include?('--enable-halfword-emulator')

        show_file('config.log') do
          sh configure.join(' ') + ' ' + erlang_confopts
        end

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

        if ENV['skip_otp_reset']
          puts "*** Skipping reset: #{source}"
        else
          sh 'git reset --hard && git clean -fd'
          rm = (DISTRO[0] == :solaris) ? 'rm' : 'rm -v'
          sh "git ls-files --others -i --exclude-standard | xargs #{rm} -f || true"
        end
      end
    end

    record_manifest 'erlang'
  end

  task :clean do
    erlang = "'#{BUILD}'/lib/erlang"
    lib = "#{erlang}/lib"

    (OTP_REMOVE + OTP_SKIP_COMPILE).each do |component|
      sh "rm -rf #{lib}/#{component}-*" unless otp_app_useful?(component)
    end

    # Remove unnecessary directories for running.
    %w[ src examples include doc man obj erl_docgen-* misc ].each do |dir|
      Find.find(erlang) do |path|
        sh "rm", "-rf", dir if File.directory?(path) && File.basename(path) == dir
      end
    end

    sh "rm #{erlang}/Install"
  end

end
