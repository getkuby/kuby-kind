require 'kuby/kind/provider'

module Kuby
  module Kind
    autoload :Config, 'kuby/kind/config'
  end
end

Kuby.register_provider(:kind, ::Kuby::Kind::Provider)
