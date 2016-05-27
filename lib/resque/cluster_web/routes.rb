module Resque
  module ClusterWeb
    module Routes

      def self.included(base)
        base.class_eval do
          mime_type :json, 'application/json'

          get "/clusters" do
            @clusters = active_clusters
            erb File.read(File.expand_path(File.dirname(__FILE__ ) + '/views/clusters.erb'))
          end
        end
      end

      def active_clusters
        clusters = []
        pings = ["GRU:test:test-cluster:heartbeats"]
        pings.each do |ping|
          clusters << {name: ping.split(":")[1], environment: ping.split(":")[2], number_of_members: 3 }
        end
        clusters
      end

      def cluster(name)
      end

      Resque::Server.tabs << 'Clusters'
    end
  end
end

 Resque::Server.class_eval do
  include Resque::ClusterWeb::Routes
end