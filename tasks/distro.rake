
task :known_distro => [ :known_mac, :known_ubuntu, :known_debian ] do
  raise 'Unknown distribution, build not supported' unless Kernel.const_defined? 'DISTRO'
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
