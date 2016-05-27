require "resque/cluster_web/version"
require "resque/cluster_web/routes"

module Resque
  module ClusterWeb
    class << self
      def redis
        redis ||= Resque.redis.redis
      end
    end
  end
end
