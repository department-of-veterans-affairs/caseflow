module Xmlenc
  module Builder
    class CipherData
      include Xmlenc::Builder::Base

      tag "CipherData"

      register_namespace "xenc", Xmlenc::NAMESPACES[:xenc]
      namespace "xenc"

      element :cipher_value, String, :namespace => "xenc", :tag => "CipherValue"
    end
  end
end
