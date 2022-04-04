module Xmlenc
  module Builder
    class EncryptionMethod
      include Xmlenc::Builder::Base

      tag "EncryptionMethod"

      register_namespace "xenc", Xmlenc::NAMESPACES[:xenc]
      namespace "xenc"

      attribute :algorithm, String, :tag => "Algorithm"
      has_one :digest_method, Xmlenc::Builder::DigestMethod

      validates :algorithm, :presence => true

      def initialize(attributes = {})
        digest_method_algorithm = attributes.delete(:digest_method_algorithm)
        if digest_method_algorithm
          attributes[:digest_method] = Xmlenc::Builder::DigestMethod.new(:algorithm => digest_method_algorithm)
        end
        super
      end
    end
  end
end
