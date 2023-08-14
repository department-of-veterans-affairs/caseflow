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

    def default_attrs_with_mst
      {
        id: generate_external_id,
        claim_id: generate_external_id,
        text: "Generic contention with MST",
        start_date: Time.zone.today,
        submit_date: 5.days.ago,
        special_issues: [{
          issue_id: generate_external_id,
          narrative: "Military Sexual Trauma (MST)",
          code: "MST"
        }]
      }
    end

    def default_attrs_with_pact
      {
        id: generate_external_id,
        claim_id: generate_external_id,
        text: "Generic contention",
        start_date: Time.zone.today,
        submit_date: 5.days.ago,
        special_issues: [{
          issue_id: generate_external_id,
          narrative: "PACT",
          code: "PACT"
        }]
      }
    end

    def default_attrs_with_mst_and_pact
      {
        id: generate_external_id,
        claim_id: generate_external_id,
        text: "Generic contention",
        start_date: Time.zone.today,
        submit_date: 5.days.ago,
        special_issues: [{
          issue_id: generate_external_id,
          narrative: "Military Sexual Trauma (MST)",
          code: "MST"
        },{
          issue_id: generate_external_id,
          narrative: "PACT",
          code: "PACT"
        }]
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

    def build_mst_contention(attrs = {})
      attrs = default_attrs_with_mst.merge(attrs)
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

    def build_pact_contention(attrs = {})
      attrs = default_attrs_with_pact.merge(attrs)
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

    def build_mst_and_pact_contention(attrs = {})
      attrs = default_attrs_with_mst_and_pact.merge(attrs)
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
