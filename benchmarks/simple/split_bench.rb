# encoding: binary

require 'rubygems'
require 'rbench'

SNIPPETS = []

SNIPPETS << ''
SNIPPETS << 'foo'
SNIPPETS << 'foo-bar'
SNIPPETS << 'foo-bar-baz'
SNIPPETS << 'foo-bar-baz-whatever'

TIMES = ARGV[0] ? ARGV[0].to_i : 100_000

RBench.run(TIMES) do

  column :times
  column :by_regex,   :title => 'regex'
  column :by_string,  :title => 'string'
  column :diff,       :title => '#2/#1', :compare => [:by_string, :by_regex]

  SNIPPETS.each do |snippet|
    report snippet.inspect do
      by_regex  { snippet.split(/-/)}
      by_string { snippet.split("-") }
    end
  end

end

#ruby 1.8.7 (2009-06-12 patchlevel 174) [i686-darwin9]
#                                       |   regex |  string |   #2/#1 |
#----------------------------------------------------------------------
#""                             x100000 |   0.073 |   0.096 |   1.31x |
#"foo"                          x100000 |   0.098 |   0.150 |   1.53x |
#"foo-bar"                      x100000 |   0.280 |   0.310 |   1.11x |
#"foo-bar-baz"                  x100000 |   0.380 |   0.411 |   1.08x |
#"foo-bar-baz-whatever"         x100000 |   0.484 |   0.514 |   1.06x |

#ruby 1.9.0 (2008-06-20 revision 17482) [i486-linux]
#                                       |   regex |  string |   #2/#1 |
#----------------------------------------------------------------------
#""                             x100000 |   0.159 |   0.242 |   1.53x |
#"foo"                          x100000 |   0.194 |   0.281 |   1.45x |
#"foo-bar"                      x100000 |   0.411 |   0.529 |   1.29x |
#"foo-bar-baz"                  x100000 |   0.523 |   0.627 |   1.20x |
#"foo-bar-baz-whatever"         x100000 |   0.571 |   0.675 |   1.18x |

#ruby 1.9.1p243 (2009-07-16 revision 24175) [i386-darwin9]
#                                       |   regex |  string |   #2/#1 |
#----------------------------------------------------------------------
#""                             x100000 |   0.104 |   0.073 |   0.70x |
#"foo"                          x100000 |   0.138 |   0.099 |   0.72x |
#"foo-bar"                      x100000 |   0.305 |   0.126 |   0.41x |
#"foo-bar-baz"                  x100000 |   0.385 |   0.153 |   0.40x |
#"foo-bar-baz-whatever"         x100000 |   0.498 |   0.207 |   0.41x |

#ruby 1.9.2dev (2009-09-19 trunk 25008) [i686-linux]
#                                       |   regex |  string |   #2/#1 |
#----------------------------------------------------------------------
#""                             x100000 |   0.101 |   0.066 |   0.66x |
#"foo"                          x100000 |   0.123 |   0.085 |   0.69x |
#"foo-bar"                      x100000 |   0.260 |   0.105 |   0.40x |
#"foo-bar-baz"                  x100000 |   0.327 |   0.125 |   0.38x |
#"foo-bar-baz-whatever"         x100000 |   0.435 |   0.191 |   0.44x |

# EOF