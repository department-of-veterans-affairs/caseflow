# frozen_string_literal: true

# ephemeral class used for caching contentions from BGS
# This is being used to determine if a contention has an exam scheduled, which is not data available on VBMS contentions

class BgsContention
  include ActiveModel::Model

  attr_accessor :reference_id, :text, :type_code, :classification_id,
                :classification_text, :medical_indicator, :orig_source_type_code, :begin_date, :claim_id,
                :special_issues

  class << self
    def fetch_all(claim_id)
      response = BGSService.new.find_contentions_by_claim_id(claim_id)

      contentions_from_bgs_response(response)
    rescue Savon::Error, BGS::ShareError
      []
    end

    def from_bgs_hash(bgs_data)
      new(
        reference_id: bgs_data[:cntntn_id],
        text: bgs_data[:clmnt_txt],
        type_code: bgs_data[:cntntn_type_cd],
        classification_id: bgs_data[:clsfcn_id],
        classification_text: bgs_data[:clsfcn_txt],
        medical_indicator: bgs_data[:med_ind],
        orig_source_type_code: bgs_data[:orig_source_type_cd],
        begin_date: bgs_data[:begin_dt],
        claim_id: bgs_data[:clm_id],
        special_issues: ensure_array_of_hashes(bgs_data.dig(:special_issues))
      )
    end

    private

    def contentions_from_bgs_response(response)
      Array.wrap(response[:contentions]).map do |contention_data|
        BgsContention.from_bgs_hash(contention_data)
      end
    end
  end

  def exam_scheduled?
    orig_source_type_code == "EXAM"
  end
end
