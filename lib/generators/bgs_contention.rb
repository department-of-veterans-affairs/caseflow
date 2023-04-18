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

    def default_attrs_with_mst
      {
        reference_id: generate_external_id,
        text: "Generic contention with MST claim",
        type_code: "SUP",
        medical_indicator: "1",
        orig_source_type_code: "APP",
        begin_date: Time.zone.today,
        claim_id: generate_external_id,
        special_issues: {
          :call_id=>"12345",
          :jrn_dt=>5.days.ago,
          :name=>"SpecialIssue",
          :spis_tc=>"MST",
          :spis_tn=>"Military Sexual Trauma (MST)"
        }
      }
    end

    def default_attrs_with_pact
      {
        reference_id: generate_external_id,
        text: "Generic contention with PACT claim",
        type_code: "SUP",
        medical_indicator: "1",
        orig_source_type_code: "APP",
        begin_date: Time.zone.today,
        claim_id: generate_external_id,
        special_issues: {
          :call_id=>"12345",
          :jrn_dt=>5.days.ago,
          :name=>"SpecialIssue",
          :spis_tc=>"PACT",
          :spis_tn=>"PACT"
        }
      }
    end

    def build(attrs = {})
      attrs = default_attrs.merge(attrs)

      OpenStruct.new(attrs).tap { |contention| Fakes::BGSService.end_product_store.create_contention(contention) }
    end

    def build_mst_contention(attrs = {})
      attrs = default_attrs_with_mst.merge(attrs)

      OpenStruct.new(attrs).tap { |contention| Fakes::BGSService.end_product_store.create_contention(contention) }
    end

    def build_pact_contention(attrs = {})
      attrs = default_attrs_with_pact.merge(attrs)

      OpenStruct.new(attrs).tap { |contention| Fakes::BGSService.end_product_store.create_contention(contention) }
    end
  end
end
