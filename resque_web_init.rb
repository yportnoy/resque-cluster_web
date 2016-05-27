require 'yaml'
require 'resque' # include resque so we can configure it

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'resque/cluster_web'