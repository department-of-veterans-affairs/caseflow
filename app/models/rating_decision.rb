# frozen_string_literal: true

# ephemeral class used for caching Rating Decisions
# A Rating Decision may or may not have an associated Rating Issue,
# notably if the type_name = "Service Connected" then we should expect an associated Rating Issue.

class RatingDecision
  include ActiveModel::Model

  attr_accessor :type_name, :rating_sequence_number, :disability_id, :disability_date, :diagnostic_text, :profile_date,
                :diagnostic_code, :benefit_type, :participant_id, :diagnostic_type

  class << self
    def from_bgs_disability(rating, disability)
      new(
        type_name: disability[:decn_tn],
        rating_sequence_number: disability[:disability_evaluations][:rating_sn],
        disability_id: disability[:dis_sn],
        diagnostic_text: disability[:disability_evaluations][:dgnstc_txt],
        diagnostic_type: disability[:disability_evaluations][:dgnstc_tn],
        diagnostic_code: disability[:disability_evaluations][:dgnstc_tc],
        disability_date: disability[:dis_dt],
        profile_date: disability[:disability_evaluations][:prfl_dt],
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
