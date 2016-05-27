module Resque
  module ClusterWeb
    module Routes

      def redis
        redis ||= Redis.new(:host => Resque.redis.redis.client.host, :port => Resque.redis.redis.client.port)
      end

      def self.included(base)
        base.class_eval do
          mime_type :json, 'application/json'

          get "/clusters" do
            erb File.read(File.expand_path(File.dirname(__FILE__ ) + '/views/clusters.erb')),
                  :locals => {:clusters => active_clusters}
          end

          get "/clusters/:name/:environment" do
            erb File.read(File.expand_path(File.dirname(__FILE__ ) + '/views/cluster.erb')),
                  :locals => {:cluster_info => cluster(params[:name], params[:environment])}
          end

          get "/clusters/:name/:environment/:member_name" do
            erb File.read(File.expand_path(File.dirname(__FILE__ ) + '/views/member.erb')),
                  :locals => {:member_info => cluster_member(params[:name], params[:environment], params[:member_name])}
          end
        end
      end

      def active_clusters
        clusters = []
        pings = redis.keys("GRU:*:*:heartbeats")
        pings.each do |ping|
          clusters << { name:               ping.split(":")[1],
                        environment:        ping.split(":")[2],
                        number_of_members:  redis.hgetall(ping).count }
        end
        clusters
      end

      def cluster(name, environment)
        cluster_key = "GRU:#{name}:#{environment}"

        running_workers_per_member = redis.hgetall("#{cluster_key}:heartbeats").inject({}) do |h,(k,v)|
          h[k] = redis.hgetall("#{cluster_key}:#{k}:workers_running").values.map(&:to_i).inject(:+)
          h
        end

        { name: name,
          environment: environment,
          running_worker_counts: redis.hgetall("#{cluster_key}:global:workers_running"),
          max_worker_counts: redis.hgetall("#{cluster_key}:global:max_workers"),
          cluster_members: running_workers_per_member,
          global_options: { rebalance_cluster:    redis.get("#{cluster_key}:rebalance"),
                            presume_dead_after:   redis.get("#{cluster_key}:presume_host_dead_after"),
                            max_workers_per_host: redis.get("#{cluster_key}:max_workers_per_host")
                          }
        }
      end

      def cluster_member(name, environment, member_name)
        cluster_key = "GRU:#{name}:#{environment}"
        cluster_member_key = "GRU:#{name}:#{environment}:#{member_name}"
        {
          cluster_name: name,
          environment: environment,
          member_name: member_name,
          last_heartbeat: redis.hget("#{cluster_key}:heartbeats","#{member_name}"),
          running_workes: redis.hgetall("#{cluster_member_key}:workers_running"),
          max_worker_counts: redis.hgetall("#{cluster_member_key}:max_workers")
        }
      end

      Resque::Server.tabs << 'Clusters'
    end
  end
end

 Resque::Server.class_eval do
  include Resque::ClusterWeb::Routes
end
