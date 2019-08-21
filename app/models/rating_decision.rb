# frozen_string_literal: true

# ephemeral class used for caching Rating Decisions
# A Rating Decision may or may not have an associated Rating Issue,
# notably if the type_name = "Service Connected" then we should expect an associated Rating Issue.

class RatingDecision
  include ActiveModel::Model

  attr_accessor :benefit_type,
                :diagnostic_code,
                :diagnostic_text,
                :diagnostic_type,
                :disability_date,
                :disability_id,
                :participant_id,
                :profile_date,
                :promulgation_date,
                :rating_sequence_number,
                :rating_reference_id,
                :type_name

  class << self
    def from_bgs_disability(rating, disability)
      latest_evaluation = Array.wrap(disability[:disability_evaluations]).max_by { |dis_eval| dis_eval[:dis_dt] } || {}
      new(
        type_name: disability[:decn_tn],
        rating_sequence_number: latest_evaluation[:rating_sn],
        rating_reference_id: latest_evaluation[:rba_issue_id], # ok if nil
        disability_id: disability[:dis_sn],
        diagnostic_text: latest_evaluation[:dgnstc_txt],
        diagnostic_type: latest_evaluation[:dgnstc_tn],
        diagnostic_code: latest_evaluation[:dgnstc_tc],
        disability_date: disability[:dis_dt],
        profile_date: rating.profile_date,
        promulgation_date: rating.promulgation_date,
        participant_id: rating.participant_id,
        benefit_type: rating.pension? ? :pension : :compensation
      )
    end

    def deserialize(hash)
      new(hash)
    end
  end

  # If you change this method, you will need to clear cache in prod for your changes to
  # take effect immediately. See DecisionReview#cached_serialized_ratings
  def serialize
    as_json.symbolize_keys
  end

  alias ui_hash serialize

  def service_connected?
    type_name == "Service Connected"
  end
end
