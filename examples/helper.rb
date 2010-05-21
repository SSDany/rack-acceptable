require 'pathname'

ROOT = Pathname(__FILE__).dirname.expand_path.parent

dir = ROOT.join('lib').to_s
$:.unshift(dir) unless $:.include?(dir)

require 'rack/acceptable'

# EOF