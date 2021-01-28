# frozen_string_literal: true

class Generators::Document
  extend Generators::Base

  class << self
    def default_attrs
      vbms_doc_version_id = generate_external_id
      {
        vbms_document_id: vbms_doc_version_id,
        series_id: generate_external_id,
        received_at: 3.days.ago,
        upload_date: 2.days.ago,
        type: ["Form 8", "Form 9", "NOD", "SOC", "SSOC"].sample,
        file_number: Random.rand(999_999_999).to_s,

        # The following are provided by VBMS or EFolder Express, but not saved to Caseflow's DB
        efolder_id: generate_external_id,
        filename: "filename-#{vbms_doc_version_id}.pdf",
        alt_types: Array.new(Random.rand(3).to_int).map { ["Form 8", "Form 9", "NOD", "SOC", "SSOC"].sample }.uniq
      }
    end

    def build(attrs = {})
      attrs = default_attrs.merge(attrs)

      # received_at and upload_date are always a Date when coming from VBMS
      attrs[:received_at] = attrs[:received_at].to_date
      attrs[:upload_date] = attrs[:upload_date].to_date
      Document.new(attrs || {})
    end
  end
end
