# frozen_string_literal: true

class Generators::BgsContention
  extend Generators::Base

  class << self
    def default_attrs
      {
        reference_id: generate_external_id,
        text: "Generic contention",
        type_code: "SUP",
        medical_indicator: "1",
        orig_source_type_code: "APP",
        begin_date: Time.zone.today,
        claim_id: generate_external_id
      }
    end

    def build(attrs = {})
      attrs = default_attrs.merge(attrs)

      OpenStruct.new(attrs).tap { |contention| Fakes::BGSService.end_product_store.create_contention(contention) }
    end
  end
end
