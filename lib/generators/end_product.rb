# frozen_string_literal: true

class Generators::EndProduct
  extend Generators::Base

  class << self
    def default_attrs
      {
        veteran_file_number: :default,
        bgs_attrs: {
          benefit_claim_id: generate_external_id,
          claim_receive_date: 10.days.ago.to_formatted_s(:short_date),
          claim_type_code: "070BVAGR",
          end_product_type_code: "070",
          payee_type_code: "00",
          status_type_code: "PEND"
        }
      }
    end

    # :bgs_attrs represents the BGS attributes passed to `from_bgs_hash`
    # :veteran_file_number should equal the veteran the EP is associated to.
    #   if you set this value to :default, the end product will return for all veterans
    def build(attrs = {})
      attrs = default_attrs.merge(attrs)
      attrs[:bgs_attrs] = default_attrs[:bgs_attrs].merge(attrs[:bgs_attrs])

      Fakes::BGSService.store_end_product_record(attrs[:veteran_file_number], attrs[:bgs_attrs])

      unless Veteran.new(file_number: attrs[:veteran_file_number]).found?
        Generators::Veteran.build(file_number: attrs[:veteran_file_number])
      end

      EndProduct.from_bgs_hash(attrs[:bgs_attrs])
    end
  end
end
