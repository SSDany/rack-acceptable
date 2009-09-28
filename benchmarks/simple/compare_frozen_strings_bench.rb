require "rubygems"
require "benchmark"

TIMES = 3_000_000

S_MALUS       = 'malus'
S_APPLETREE   = 'malus'
S_BETULA      = 'betula'

F_MALUS       = 'malus'.freeze
F_APPLETREE   = 'malus'.freeze
F_BETULA      = 'betula'.freeze

Benchmark.bmbm do |x|
  x.report( "when not frozen == not frozen" ) { TIMES.times { S_MALUS == S_APPLETREE  } }
  x.report( "when not frozen != not frozen" ) { TIMES.times { S_MALUS == S_BETULA     } }
  x.report( "when not frozen == frozen"     ) { TIMES.times { S_MALUS == F_APPLETREE  } }
  x.report( "when not frozen != frozen"     ) { TIMES.times { S_MALUS == F_BETULA     } }
  x.report( "when frozen == frozen"         ) { TIMES.times { F_MALUS == F_APPLETREE  } }
  x.report( "when frozen != frozen"         ) { TIMES.times { F_MALUS == F_BETULA     } }
  x.report( "when frozen == not frozen"     ) { TIMES.times { F_MALUS == S_APPLETREE  } }
  x.report( "when frozen != not frozen"     ) { TIMES.times { F_MALUS == S_BETULA     } }
end

# EOF