module Xmlenc
  module Builder
    class ReferenceList
      include Xmlenc::Builder::Base

      tag "ReferenceList"

      register_namespace "xenc", Xmlenc::NAMESPACES[:xenc]
      namespace "xenc"

      has_many :data_references, Xmlenc::Builder::DataReference, :xpath => "./"

      def add_data_reference(data_id)
        self.data_references ||= []
        self.data_references << DataReference.new(:uri => "##{data_id}")
      end
    end
  end
end