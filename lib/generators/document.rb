class Generators::Document
  extend Generators::Base

  class << self
    def default_attrs
      {
        vbms_document_id: generate_external_id,
        filename: "filename.pdf",
        received_at: 3.days.ago
      }
    end

    def build(attrs = {})
      attrs = default_attrs.merge(attrs)

      # received_at is always a Date when coming from VBMS
      attrs[:received_at] = attrs[:received_at].to_date

      Document.new(attrs || {})
    end
  end
end
