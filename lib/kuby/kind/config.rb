module Kuby
  module Kind
    class Config
      attr_reader :exposed_ports, :kubernetes_version

      def initialize(&block)
        @exposed_ports = []
      end

      def expose_port(port)
        @exposed_ports << port
      end

      def hide_port(port)
        @exposed_ports.delete(port)
      end

      def use_kubernetes_version(version)
        @kubernetes_version = version
      end
    end
  end
end
