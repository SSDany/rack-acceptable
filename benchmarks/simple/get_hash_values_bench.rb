require "benchmark"

S_MALUS = 'malus'
F_MALUS = 'malus'.freeze

HASH1  = { S_MALUS  => :appletree }
HASH2  = { F_MALUS  => :appletree }

TIMES = 3_000_000

Benchmark.bmbm do |x|
  x.report( "mutable key hash | literal"    ) { TIMES.times { HASH1['malus']  } }
  x.report( "mutable key hash | not frozen" ) { TIMES.times { HASH1[S_MALUS]  } }
  x.report( "mutable key hash | frozen"     ) { TIMES.times { HASH1[F_MALUS]  } }
  x.report( "frozen key hash  | literal"    ) { TIMES.times { HASH2['malus']  } }
  x.report( "frozen key hash  | not frozen" ) { TIMES.times { HASH2[S_MALUS]  } }
  x.report( "frozen key hash  | frozen"     ) { TIMES.times { HASH2[F_MALUS]  } }
end

# EOF