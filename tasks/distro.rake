task :known_distro => :known_checkout do
  distro = detect_distro()
  raise 'Unknown distribution, build not supported' unless distro
  DISTRO = distro
end

task :known_checkout do
  if ! system("git", "diff-index", "--quiet", "HEAD")
    diffs = %x[ git diff-index HEAD ]
    msg = "This checkout is not clean:\n#{diffs}"
    raise msg unless ENV['unclean']

    puts "WARNING: #{msg}\n"
  end

  # TODO: Maybe check for unknown files
  # git ls-files --others --exclude-standard

  commit = %x[ git rev-parse --verify HEAD ]
  raise "Failed to identify this Git commit ID" unless $?.success?

  puts "Git commit: #{commit.chomp}"
end
