
task :known_distro => [ :known_mac, :known_ubuntu, :known_debian, :known_redhat, :known_opensuse, :known_slf, :known_solaris ] do
  raise 'Unknown distribution, build not supported' unless Object.const_defined? 'DISTRO'
end

task :known_mac do
  DISTRO = [:osx, 10.0] if `uname`.chomp == 'Darwin'
end

task :known_ubuntu do
  if File.exist? '/etc/lsb-release'
    info = Hash[ *File.new('/etc/lsb-release').lines.map{ |x| x.split('=').map { |y| y.chomp } }.flatten ]
    if info['DISTRIB_ID'] == 'Ubuntu'
      DISTRO = [:ubuntu, info['DISTRIB_RELEASE']]
    end
  end
end

task :known_debian do
  ver = '/etc/debian_version'
  DISTRO = [:debian, File.new(ver).readline.chomp] if !File.exist?('/etc/lsb-release') && File.exist?(ver)
end

task :known_redhat do
  if File.exist? '/etc/fedora-release'
    release = File.new('/etc/fedora-release').readline.match(/Fedora release (\d+)/)[1]
    DISTRO = [:fedora, release]
  end
  if File.exist? '/etc/redhat-release'
    release = File.new('/etc/redhat-release').readline.match(/Red Hat Enterprise Linux Server release (\d+)/)[1]
    DISTRO = [:fedora, release]
  end
end

task :known_slf do
  if File.exist? '/etc/redhat-release'
    release = File.new('/etc/redhat-release').readline.match(/Scientific Linux SLF release (\d+)/)[1]
    DISTRO = [:slf, release]

    if RUBY_VERSION <= '1.8.7'
      raise 'Version of ruby is too old. Consider installing a more recent version'
    end
  end
end

task :known_opensuse do
  if File.exist? '/etc/SuSE-release'
    release = File.new('/etc/SuSE-release').readline.match(/openSUSE (\d+)/)[1]
    DISTRO = [:opensuse, release]
  end
end

task :known_solaris do
  if `uname`.chomp == "SunOS"
    DISTRO = [:solaris, `uname -r`.chomp]
  end
end
