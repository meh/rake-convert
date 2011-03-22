EXPORT = [:CC, :CXX]

$convert   = false
$makefile  = ''
$configure = ''

clean = []

if (Rake::Task[:clean] rescue nil) || (Rake::Task[:clobber] rescue nil)
  if defined?(CLOBBER)
    CLOBBER.include 'configure', 'Makefile'
  end

  if (Rake::Task[:clobber] rescue nil)
    clean << :clobber
  elsif (Rake::Task[:clean] rescue nil)
    clean << :clean
  end
end

# Makefile stuff
  def sh (args)
    if $convert
      puts "Makefile: #{args}"
      $makefile << "\t#{args.gsub(/\$\{(.*?)\}/, '$(\1)')}\n"
    else
      super(args)
    end
  end
# Makefile stuff

# configure stuff
  alias __have_library have_library
  alias __have_func    have_func
  alias __have_macro   have_macro
  alias __check_sizeof check_sizeof

  def have_library (*args, &block)
    if $generate
    end

    __have_library(*args, &block)
  end

  def have_func (*args, &block)
    if $generate
    end

    __have_func(*args, &block)
  end

  def have_macro (*args, &block)
    if $generate
    end

    __have_macro(*args, &block)
  end

  def check_sizeof (*args, &block)
    if $generate
    end

    __check_sizeof(*args, &block)
  end
# configure stuff

desc 'Convert the Rakefile to Makefile/configure'
task :convert => clean do |task|
  class << task
    def escape (name)
      name.gsub(/[:]/, '_')
    end

    def do_make (task)
      return if !task || (@done ||= []).member?(task)

      task.prerequisites.each {|p|
        scope = task.name.split(':')
        scope.pop

        t = Rake::Task[Rake::Task.scope_name(scope, p)] rescue nil

        if !t
          t = Rake::Task[p] rescue nil
          t = nil unless t.is_a?(Rake::FileTask)
        end

        do_make(t)
      }

      $makefile << "\n#{escape(task.name)}: #{task.prerequisites.map {|p|
        scope = task.name.split(':')
        scope.pop

        t = Rake::Task[Rake::Task.scope_name(scope, p)] rescue nil

        if !t
          t = Rake::Task[p] rescue nil
          t = nil unless t.is_a?(Rake::FileTask)
        end

        escape(t.name) if t
      }.compact.join(' ')}\n"

      task.invoke

      @done << task
    end

    def add_env (*names)
      names.flatten.compact.each {|name|
        $makefile << "#{name} = #{eval("::#{name}")}\n" if eval("::#{name}") rescue nil
      }
    end
  end

  $convert = true

  task.add_env(EXPORT)

  $makefile << "all: default\n"

  Rake::Task.tasks.each {|t|
    next if t.name == 'clean' || t.name == 'clobber'

    task.do_make(t)
  }

  $makefile << "\nclean:\n"
  CLEAN.exclude('Makefile', 'configure').each do |f|
    $makefile << "\trm -rf #{f}\n"
  end
  
  $makefile << "\nclobber:\n"
  CLEAN.exclude('Makefile', 'configure').each do |f|
    $makefile << "\trm -rf #{f}\n"
  end

  CLOBBER.exclude('Makefile', 'configure').each do |f|
    $makefile << "\trm -rf #{f}\n"
  end
  
  File.open('Makefile', 'w') {|f|
    f.write $makefile
  }

  $makefile = ''
end
