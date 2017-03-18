class Generators::Document
  extend Generators::Base

  class << self
    def build(attrs)
      attrs[:vbms_document_id] = generate_external_id

      # received_at is always a Date when coming from VBMS
      attrs[:received_at] = (attrs[:received_at] || Time.zone.now).to_date

      Document.new(attrs || {})
    end
  end
end
