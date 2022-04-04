module Xmlenc
  module Builder
    class DigestMethod
      include Xmlenc::Builder::Base

      tag "DigestMethod"

      register_namespace "ds", Xmlenc::NAMESPACES[:ds]
      namespace "ds"

      attribute :algorithm, String, :tag => "Algorithm"

      validates :algorithm, :presence => true
    end
  end
end
