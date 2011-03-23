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
def die (text)
  if $convert
    $configure << %{

if [[ "$LAST" == "no" ]]; then
  echo -e "#{text}"
  do_exit
fi

    }
  else
    fail(text)
  end
end

if $".grep(/mkmf\.rb$/).first
  alias __have_header   have_header
  alias __have_library  have_library
  alias __have_func     have_func
  alias __have_macro    have_macro
  alias __check_sizeof  check_sizeof
  alias __create_header create_header

  def have_header (header, preheaders = nil, &block)
    source = nil
    result = __have_header(header, preheaders) {|c|
      source = block ? block.call(c) : c
    }

    source.sub!('#include "ruby.h"', '')

    if $convert
      $configure << %{

cat > $FILE.c <<EOF
#{source}
EOF

echo -n "Checking for #{header}... "
if [[ "`($CC $CFLAGS -pipe -o $FILE -c $FILE.c) 2>&1`" == "" ]]; then
  DEFS="$DEFS\\n#define #{"HAVE_#{header.tr_cpp}"} 1"

  echo yes
else
  echo no
fi

      }
    end

    $convert ? false : result
  end

  def have_library (lib, func = nil, headers = nil, &block)
    source = nil
    result = __have_library(lib, func, headers) {|c|
      source = block ? block.call(c) : c
    }

    source.sub!('#include "ruby.h"', '')

    if $convert
      $configure << %{

cat > $FILE.c <<EOF
#{source}
EOF

echo -n "Checking for #{lib}... "
if [[ "`($CC $CFLAGS -pipe -o $FILE $FILE.c -l#{lib} $LIBS) 2>&1`" == "" ]]; then
  LAST=yes

  LIBS="$LIBS -l#{lib}"
else
  LAST=no
fi

echo $LAST

      }
    end

    $convert ? false : result
  end

  def have_func (func, headers = nil, &block)
    source = nil
    result = __have_func(func, headers) {|c|
      source = block ? block.call(c) : c
    }

    source.sub!('#include "ruby.h"', '')

    if $convert
      $configure << %{

cat > $FILE.c <<EOF
#{source}
EOF

echo -n "Checking for #{func}()#{" in #{[headers].flatten.join(' ')}" if headers}... "
if [[ "`($CC $CFLAGS -Wall -pipe -o $FILE -c $FILE.c) 2>&1`" == "" ]]; then
  DEFS="$DEFS\\n#define #{"HAVE_#{func.tr_cpp}"} 1"

  echo yes
else
  echo no
fi

      }
    end

    $convert ? false : result
  end

  def have_macro (macro, headers = nil, opts = '', &block)
    source = nil
    result = __have_macro(macro, headers, opts) {|c|
      source = block ? block.call(c) : c
    }

    source.sub!('#include "ruby.h"', '')

    if $convert
      $configure << %{

cat > $FILE.c <<EOF
#{source}
EOF

echo -n "Checking for #{macro}#{" in #{[headers].flatten.join(' ')}" if headers}... "
if [[ "`($CC $CFLAGS -pipe -o $FILE -c $FILE.c) 2>&1`" == "" ]]; then
  DEFS="$DEFS\\n#define #{"HAVE_#{macro.tr_cpp}"} 1"

  echo yes
else
  echo no
fi

      }
    end

    $convert ? false : result
  end

  def check_sizeof (type, headers = nil, opts = '', &block)
    source = nil
    result = __check_sizeof(type, headers, opts) {|c|
      source = block ? block.call(c) : c
    }

    source.sub!('#include "ruby.h"', '')

    if $convert
      $configure << %{

cat > $FILE.c <<EOF
#{source}
EOF

$CC $CFLAGS -o $FILE $FILE.c

echo -n "Checking size of #{type}#{" in #{[headers].flatten.join(' ')}" if headers}... "
if [[ "`($CC $CFLAGS -pipe -o $FILE $FILE.c) 2>&1`" == "" ]]; then
  SIZE=$(exec $FILE)
  DEFS="$DEFS\\n#define #{"SIZEOF_#{type.tr_cpp}"} $SIZE"

  echo $SIZE
else
  echo no

  echo "Could not define size of #{type}"

  exit 1
fi

      }
    end

    $convert ? false : result
  end

  def create_header (header = 'extconf.h')
    if $convert
      $configure << %{

cat > #{header} <<EOF
#ifndef #{header.tr_cpp}
#define #{header.tr_cpp}
EOF

echo -e $DEFS >> #{header}

cat >> #{header} <<EOF

#endif
EOF

DEFS=

      }
    end

    __create_header(header)
  end
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
        $makefile << "#{name} = #{eval("::#{name.to_s.gsub(/\$\{(.*?)\}/, '$(\1)')}")}\n" if eval("::#{name}") rescue nil
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

  File.open('configure', 'w', 0755) {|f|
    f.puts 'CC=${CC:-gcc}'
    f.puts 'LIBS='
    f.puts 'FILE=`mktemp -u`'
    f.puts 'DEFS='

    f.puts 'function do_clean { rm -f $FILE; rm -f $FILE.c; rm -f $FILE.o; }'
    f.puts 'function do_exit { do_clean; exit 1; }'

    f.puts $configure

    f.puts 'do_clean'
  }

  $makefile = ''
  $configure = ''
end
