task :known_distro do
  distro = detect_distro()
  raise 'Unknown distribution, build not supported' unless distro
  DISTRO = distro
end
