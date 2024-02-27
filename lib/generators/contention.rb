# frozen_string_literal: true

class Generators::Contention
  extend Generators::Base

  class << self
    def default_attrs
      {
        id: generate_external_id,
        claim_id: generate_external_id,
        text: "Generic contention",
        start_date: Time.zone.today,
        submit_date: 5.days.ago
      }
    end

    def build(attrs = {})
      attrs = default_attrs.merge(attrs)
      claim_id = attrs[:claim_id]
      disposition = attrs.delete(:disposition)

      OpenStruct.new(attrs).tap do |contention|
        Fakes::BGSService.end_product_store.create_contention(contention)

        if disposition
          disposition_record = OpenStruct.new(
            claim_id: claim_id,
            contention_id: contention.id,
            disposition: disposition
          )
          Fakes::BGSService.end_product_store.create_disposition(disposition_record)
        end
      end
    end
  end
end
