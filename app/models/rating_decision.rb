# frozen_string_literal: true

# ephemeral class used for caching Rating Decisions
# A Rating Decision may or may not have an associated Rating Issue,
# notably if the type_name = "Service Connected" then we should expect an associated Rating Issue.

class RatingDecision
  include ActiveModel::Model
  include LatestRatingDisabilityEvaluation

  attr_accessor :begin_date,
                :benefit_type,
                :converted_begin_date,
                :diagnostic_code,
                :diagnostic_text,
                :diagnostic_type,
                :disability_id,
                :original_denial_date,
                :original_denial_indicator,
                :participant_id,
                :profile_date,
                :promulgation_date,
                :rating_sequence_number,
                :rating_issue_reference_id,
                :type_name

  class << self
    def from_bgs_disability(rating, disability)
      latest_evaluation = latest_disability_evaluation(disability)
      new(
        type_name: disability[:decn_tn],
        rating_sequence_number: latest_evaluation[:rating_sn],
        rating_issue_reference_id: latest_evaluation[:rba_issue_id], # ok if nil
        disability_id: disability[:dis_sn],
        diagnostic_text: latest_evaluation[:dgnstc_txt],
        diagnostic_type: latest_evaluation[:dgnstc_tn],
        diagnostic_code: latest_evaluation[:dgnstc_tc],
        begin_date: latest_evaluation[:begin_dt],
        converted_begin_date: latest_evaluation[:conv_begin_dt],
        original_denial_date: disability[:orig_denial_dt],
        original_denial_indicator: disability[:orig_denial_ind],
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

  def decision_text
    service_connected? ? service_connected_decision_text : not_service_connected_decision_text
  end

  def decision_date
    return promulgation_date if rating_issue?

    original_denial_date || converted_begin_date || begin_date
  end

  def contestable?
    return true if rating_issue?

    return false unless decision_date

    the_decision = decision_date.to_date
    the_promulgation = promulgation_date.to_date
    the_decision.between?((the_promulgation - 10.days), (the_promulgation + 10.days))
  end

  def rating_issue?
    rating_issue_reference_id.present?
  end

  def reference_id
    disability_id
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

  private

  def service_connected_decision_text
    "#{diagnostic_type} (#{diagnostic_text}) is granted as Service Connected"
  end

  def not_service_connected_decision_text
    "#{diagnostic_type} (#{diagnostic_text}) is denied as Not Service Connected"
  end
end
