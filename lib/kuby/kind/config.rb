module Kuby
  module Kind
    class Config
      attr_reader :exposed_ports

      def initialize(&block)
        @exposed_ports = []
      end

      def expose_port(port)
        @exposed_ports << port
      end

      def hide_port(port)
        @exposed_ports.delete(port)
      end
    end
  end
end
