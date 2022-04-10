require 'kuby'
require 'kind-rb'
require 'open3'

module Kuby
  module Kind
    class Provider < ::Kuby::Kubernetes::Provider
      STORAGE_CLASS_NAME = 'standard'.freeze
      DEFAULT_EXPOSED_PORTS = [80, 443].freeze

      attr_reader :config

      def configure(&block)
        config.instance_eval(&block) if block
      end

      def kubeconfig_path
        File.join(
          kubeconfig_dir, "#{cluster_name}-kubeconfig.yaml"
        )
      end

      def storage_class_name
        STORAGE_CLASS_NAME
      end

      def setup
        @setting_up = true
        ensure_cluster!
      end

      def deploy
        ensure_cluster!
        load_images

        super
      end

      def after_configuration
        if nginx_ingress = environment.kubernetes.plugin(:nginx_ingress)
          nginx_ingress.configure do
            provider('kind') unless provider
          end
        end
      end

      private

      def after_initialize
        @already_ensured = false
        @config = Config.new

        configure do
          DEFAULT_EXPOSED_PORTS.each do |port|
            expose_port port
          end
        end

        kubernetes_cli.before_execute do
          ensure_cluster!
        end
      end

      def load_images
        require 'pry-byebug'
        Kuby.logger.info("Loading Docker images into Kind cluster...")

        node_name = "#{cluster_name}-control-plane"
        loaded_images = YAML.load(
          docker_cli.exec_capture(
            container: node_name,
            command: '/usr/local/bin/crictl images --digests -o yaml'
          )
        )

        loaded_digests = loaded_images['images'].map do |image|
          algo, digest = image['id'].split(':')
          { algo: algo, digest: digest }
        end

        environment.kubernetes.docker_images.each do |image|
          image = image.current_version
          images = docker_cli.images(image.image_url, digests: true)
          image_info = images.find { |img| img[:tag] == image.main_tag }

          if image_info
            algo, _ = image_info[:digest].split(':')

            loaded_digest = loaded_digests.find do |loaded_digest|
              algo == loaded_digest[:algo] && loaded_digest[:digest].start_with?(image_info[:id])
            end

            if loaded_digest
              Kuby.logger.info("Skipping #{image.image_url}@#{loaded_digest[:algo]}:#{loaded_digest[:digest]} because it's already loaded.")
              next
            end
          end

          # Only load the main tag because it's so darn expensive to load large
          # images into Kind clusters. Kind doesn't seem to realize images with
          # the same SHA but different tags are the same, :eyeroll:
          cmd = [
            KindRb.executable,
            'load', 'docker-image', "#{image.image_url}:#{image.main_tag}",
            '--name', cluster_name
          ]

          system(cmd.join(' '))
        end

        Kuby.logger.info("Docker images loaded into Kind cluster successfully.")
      end

      def ensure_cluster!
        return if @already_ensured

        if !cluster_defined? || !cluster_running? || !cluster_reachable?
          recreate_cluster!

          unless @setting_up
            Kuby.logger.info("Local Kind cluster (re)created, please run `kuby setup`.")
            exit 0
          end
        end

        @already_ensured = true
      end

      def recreate_cluster!
        delete_cluster! if cluster_running?
        create_cluster!
      end

      def delete_cluster!
        cmd = [
          KindRb.executable, 'delete', 'cluster',
          '--name', cluster_name,
          '--kubeconfig', kubeconfig_path
        ]

        system(cmd.join(' '))

        if $?.exitstatus != 0
          raise 'Kind command failed'
        end
      end

      def create_cluster!
        cmd = [
          KindRb.executable, 'create', 'cluster',
          '--name', cluster_name,
          '--kubeconfig', kubeconfig_path,
        ]

        if config.kubernetes_version
          cmd += ['--image', "kindest/node:v#{config.kubernetes_version}"]
        end

        if (cluster_config = make_cluster_config)
          cmd << '--config -'

          Open3.pipeline_w(cmd.join(' ')) do |stdin, wait_threads|
            stdin.puts(YAML.dump(cluster_config))
            stdin.close
            wait_threads.each(&:join)

            if wait_threads.first.value.exitstatus != 0
              raise 'Kind command failed'
            end
          end
        else
          system(cmd.join(' '))

          if $?.exitstatus != 0
            raise 'Kind command failed'
          end
        end
      end

      def make_cluster_config
        return nil if config.exposed_ports.empty?

        {
          'kind' => 'Cluster',
          'apiVersion' => 'kind.x-k8s.io/v1alpha4',
          'nodes' => [{
            'role' => 'control-plane',
            'kubeadmConfigPatches' => [
              <<~END,
                kind: InitConfiguration
                nodeRegistration:
                  kubeletExtraArgs:
                    node-labels: "ingress-ready=true"
              END
            ],
            'extraPortMappings' => config.exposed_ports.map do |port|
              { 'containerPort' => port, 'hostPort' => port, 'protocol' => 'TCP' }
            end
          }]
        }
      end

      def cluster_defined?
        return false if !File.exist?(kubeconfig_path)

        kubeconfig = YAML.load_file(kubeconfig_path)
        cluster_config = (kubeconfig['clusters'] || []).find do |cluster|
          cluster['name'] == context
        end

        !!cluster_config
      end

      def cluster_running?
        cmd = [KindRb.executable, 'get', 'clusters']
        cluster_names = `#{cmd.join(' ')}`.strip.split("\n")
        cluster_names.include?(cluster_name)
      end

      def cluster_reachable?
        cmd = [
          kubernetes_cli.executable,
          '--kubeconfig', kubeconfig_path,
          '--context', context,
          'get', 'ns'
        ]

        `#{cmd.join(' ')}`
        $?.success?
      end

      def cluster_name
        @cluster_name ||= environment.app_name.downcase
      end

      def context
        @context ||= "kind-#{cluster_name}"
      end

      def kubeconfig_dir
        @kubeconfig_dir ||= File.join(
          Dir.tmpdir, 'kuby-kind'
        )
      end

      def docker_cli
        @docker_cli ||= Docker::CLI.new
      end
    end
  end
end