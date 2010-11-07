# Miscellaneous utilities

require 'uri'
require 'find'
require 'tmpdir'

$stdout_old = $stdout
$stderr_old = $stderr

log_filename = "rake.log"
File.unlink(log_filename) if File.exists?(log_filename)

unless ARGV[0] == 'environment:shell' || ENV['raw']
  ["$stdout", "$stderr"].each do |std|
    rd, wr = IO.pipe
    if fork
      rd.close
      wr.sync = true
      eval "#{std}.reopen(wr)"
      eval "#{std}.sync = true"
      #Process.wait
    else
      # Child
      wr.close
      begin
        # Input must be forked.
        label = std[1..-1].upcase
        File.open(log_filename, 'a') do |f|
          f.sync = true
          while(line = rd.gets)
            eval "#{std}_old.puts(line)"
            f.puts([label, line].join(' '))
          end
        end
      ensure
        rd.close
        exit
      end
    end
  end
end

require File.dirname(__FILE__) + '/distros'

def package_dep opts
  # Unfortunately the dependency must be defined after the OS is detected,
  # Even if this task is a no-op, if other tasks depend on it, they will re-run
  # if this task runs. Therefore it must not be defined at all for un-requested
  # distros. That means calling detect_distro() now and presumably later in :known_distro.
  distro = detect_distro()

  distros = opts.delete :distros
  if distros && distros.none?{|x| x == distro[0]}
    puts "#{distro[0]} does not need #{opts.inspect}"
    return "/" # Return a file dependency that will presumably always work.
  end

  #not_distros = opts.delete :except
  #if not_distros && not_distros.any?{|x| x == distro[0]}
  #  puts "#{distro[0]} does not need #{opts.inspect}"
  #  return "/" # Return a file dependency that will presumably always work.
  #end

  puts "Package dependency for #{distro[0]}: #{opts.inspect}"
  program_file, package = opts.to_a.first

  Rake.application.in_explicit_namespace(':') do
    file program_file do
      case distro[0]
        when :ubuntu, :debian
          installed = `dpkg --list`.split("\n").map { |x| x.split[1] } # Hm, this is out of scope if defined outside.
          if installed.none? { |pkg| pkg == package }
            sh "sudo apt-get -y install #{package}"
          end
        when :solaris
          installed = `pkg-get -l`.split("\n")
          if installed.none? { |pkg| pkg == package }
            sh "sudo pkg-get install #{package}"
          end
        when :osx
          installed = `brew list`.split("\n")
          if installed.none? { |pkg| pkg == package }
            sh "sudo brew install #{package}"
          end
        else
          puts "Skipping package requirement '#{package}' on an unsupported platform"
      end
    end
  end

  program_file
end

# Run GNU Make
def gmake(cmd="")
  gmake = DISTRO[0] == :solaris ? 'gmake' : 'make'
  sh "#{gmake} #{cmd}"
end

# Mark a program as authorized to listen on a low port in Linux.
def set_port_cap file
  return unless [:ubuntu, :debian].include? DISTRO[0]
  sh "sudo setcap cap_net_bind_service=+ep #{File.expand_path file}"
end

# TODO: Get rid of this. Packages should be installed as a dependency of other software, declared by package_dep().
def install_packages packages
  case DISTRO[0]
    when :opensuse
      installed = %x[rpm -qa].split("\n")
      packages.select{|pkg| ! installed.detect{|d| d =~ /^#{Regexp.escape(pkg)}/ } }.each do |package|
        # puts "Installing #{package} ..."
        %x[sudo zypper install '#{package}']
      end
    when :solaris
      installed = `pkg-get -l`.split("\n")
      packages.select{|pkg| ! installed.include? pkg }.each do |package|
        sh "sudo pkg-get install #{package}"
      end
    else
      installed = `dpkg --list`.split("\n").map { |x| x.split[1] } # Hm, this is out of scope if defined outside.
      packages.select{ |pkg| ! installed.include? pkg }.each do |package|
      sh "sudo apt-get -y install #{package}"
    end
  end
end

def canonical_path path
  path.gsub(/[\.\d]*$/, '')
end


def ln_canonical path
  puts "#{path} => #{canonical_path path}"
  FileUtils.ln_sf path, canonical_path(path)
end

def show_file filename
  begin
    yield
  ensure
    puts "== Output of #{filename} =="
    sh "cat #{filename}"
    puts "== End of #{filename} =="
  end
end

def with_autoconf ver
  files = %w[ autoconf autoheader autom4te ].map { |x| "#{BUILD}/bin/#{x}#{ver}" }

  begin
    files.each { |x| ln_canonical x }
    yield
  ensure
    files.each { |x| FileUtils.rm_f(canonical_path(x)) }
  end
end

def copy_parts opts
  Dir.chdir opts[:source] do
    sh "tar cf - #{opts[:dirs].join ' '} | tar xvf - --directory #{opts[:target]}"
  end
end

def in_build_dir label
  label = File.basename Dir.getwd if label.nil?
  Dir.mktmpdir "#{label}_build" do |dir|
    Dir.chdir dir do
      yield
    end
  end
end

def compress_beams source
  Find.find(source) do |path|
    if File.file?(path) && path.match(/\.beam$/) && ENV['skip_compress_beam'].nil?
      sh "gzip -9 '#{path}'"
      sh "mv '#{path}'.gz '#{path}'"
    end
  end
end

def record_manifest task_name
  return if ENV['manifest'].nil? || ENV['manifest'] == ""

  task_name = File.basename(task_name) if task_name =~ /\//

  sh "mkdir -p #{MANIFESTS}"
  seen = {}
  Dir.glob("#{MANIFESTS}/*").each do |manifest|
    File.new(manifest).each do |line|
      path = line.chomp
      raise "Woa! #{path} is in #{task_name} but was already seen in #{seen[path]}" if seen[path]
      seen[path] = File.basename(manifest)
    end
  end

  unseen = []
  Find.find(BUILD) do |path|
    if File.directory? path
      Find.prune if path == MANIFESTS
    else
      if seen[path]
        #puts "#{path} seen: #{seen[path]}"
      else
        unseen.push path
      end
    end
  end

  manifest = File.new("#{MANIFESTS}/#{task_name}", 'w')
  manifest.write(unseen.join("\n"))
  manifest.write("\n")
  manifest.close
end

def run_task name
  task = Rake::Task[name]
  task.reenable if task.methods.include?("reenable")
  task.invoke
end

def configure_cmd(source, opts={})
  libs = ["#{BUILD}/lib"]

  if DISTRO[0] == :solaris
    libs += %w[ /opt/csw/lib /opt/csw/gcc4/lib /opt/csw/lib/i386 ]
  end

  ldflags = libs.map{|lib| "-R#{lib} -L#{lib}"}.join(' ')
  ldflags += ' -llber' if DISTRO[0] == :solaris

  env = "LDFLAGS='#{ldflags}' CFLAGS='-I#{BUILD}/include/js'"
  prefix = (opts[:prefix].nil? || opts[:prefix]) ? "--prefix=#{COUCH_BUILD}" : ""
  return "env #{env} #{source}/configure #{prefix} --with-erlang=#{BUILD}/lib/erlang/usr/include"
end

def git_checkout_name(url)
  URI.escape(url, /[\/:]/)
end

def git_checkout(url_and_commit, opts={})
  remote, commit = url_and_commit.split
  checkout = "#{HERE}/git-build/#{git_checkout_name(remote + ':' + commit)}"
  return checkout if opts[:noop]

  fetch = false
  if File.directory?(checkout) || File.symlink?(checkout)
    puts "Using #{checkout} for build from Git"
    fetch = true
  elsif File.exists? checkout
    raise "Don't know what to do with #{checkout}"
  else
    sh "git clone '#{remote}' '#{checkout}'"
  end

  Dir.chdir checkout do
    sh "git fetch origin" if fetch
    sh "git checkout #{commit}"
    sh "git reset --hard"
    sh "git clean -f -d"
    # Forego a nice rm command to get OS-independence.
    #rm = (DISTRO[0] == :solaris) ? 'rm' : 'rm -v'
    rm = 'rm'
    sh "git ls-files --others -i --exclude-standard | xargs #{rm} || true"
  end

  return checkout
end

module Rake
  module TaskManager
    def in_explicit_namespace(name)
      oldscope = @scope;
      @scope = Array.new();
      # build scope name list from name here
      ns = NameSpace.new(self, @scope);
      yield(ns)
      ns
      ensure
        @scope = oldscope;
    end
  end
end

#
# Build Places
#

DEPS = "#{HERE}/dependencies"
BUILD = ENV['prefix'] || "#{HERE}/build"
JS_LIB = "#{BUILD}/bin/js-config"
ERL_BIN = "#{BUILD}/bin/erl"
ICU_BIN = "#{BUILD}/bin/icu-config"
COUCH_SOURCE = ENV['git'] ? git_checkout(ENV['git'], :noop => true) : "#{DEPS}/couchdb"
COUCH_BUILD = ENV['couchdb_build'] || BUILD
COUCH_BIN = "#{COUCH_BUILD}/bin/couchdb"
MANIFESTS = "#{BUILD}/manifests"

PIDS = "#{BUILD}/var/run/couchdb"

AUTOCONF_213 = "#{BUILD}/bin/autoconf2.13"
AUTOCONF_259 = "#{BUILD}/bin/autoconf2.59"
