require 'kuby'
require 'kind-rb'

module Kuby
  module Kind
    class Provider < ::Kuby::Kubernetes::Provider
      STORAGE_CLASS_NAME = 'default'.freeze

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

      def before_deploy(*)
        ensure_cluster!
        load_images
      end

      private

      def after_initialize
        @already_ensured = false

        kubernetes_cli.before_execute do
          ensure_cluster!
        end
      end

      def load_images
        Kuby.logger.info("Loading Docker images into Kind cluster...")

        environment.kubernetes.docker_images.each do |image|
          image = image.current_version

          image.tags.map do |tag|
            cmd = [
              KindRb.executable,
              'load', 'docker-image', "#{image.image_url}:#{tag}",
              '--name', cluster_name
            ]

            system({ 'KUBECONFIG' => kubeconfig_path }, cmd.join(' '))
          end
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
        if cluster_defined? || cluster_running?
          delete_cluster!
        end

        create_cluster!
      end

      def delete_cluster!
        cmd = [KindRb.executable, 'delete', 'cluster', '--name', cluster_name]
        system({ 'KUBECONFIG' => kubeconfig_path }, cmd.join(' '))
      end

      def create_cluster!
        cmd = [KindRb.executable, 'create', 'cluster', '--name', cluster_name]
        system({ 'KUBECONFIG' => kubeconfig_path }, cmd.join(' '))
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
    end
  end
end