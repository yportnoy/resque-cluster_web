require 'yaml'
require 'resque' # include resque so we can configure it
require 'resque-cleaner'
require File.expand_path(File.dirname(__FILE__ ) + '/../lib/resque/cluster_web')
