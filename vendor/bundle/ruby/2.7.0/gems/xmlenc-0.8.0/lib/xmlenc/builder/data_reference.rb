module Xmlenc
  module Builder
    class DataReference
      include Xmlenc::Builder::Base

      tag "DataReference"

      register_namespace "xenc", Xmlenc::NAMESPACES[:xenc]
      namespace "xenc"

      attribute :uri, String, :tag => "URI"
    end
  end
end