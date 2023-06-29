# frozen_string_literal: true

# ephemeral class used for caching Rating Decisions
# A Rating Decision may or may not have an associated Rating Issue,
# notably if the type_name = "Service Connected" then we should expect an associated Rating Issue.

class RatingDecision
  include ActiveModel::Model

  # the flexible window for calculating the contestable decision date.
  # this is the number of days +/- the effective date.
  GRACE_PERIOD = 10

  attr_accessor :begin_date,
                :benefit_type,
                :converted_begin_date,
                :diagnostic_code,
                :diagnostic_text,
                :diagnostic_type,
                :disability_date,
                :disability_id,
                :original_denial_date,
                :original_denial_indicator,
                :participant_id,
                :previous_rating_sequence_number,
                :profile_date,
                :promulgation_date,
                :rating_sequence_number,
                :rating_issue_reference_id,
                :type_name,
                :special_issues,
                :rba_contentions_data

  class << self
    # rubocop:disable Metrics/MethodLength
    def from_bgs_disability(rating, disability)
      latest_evaluation = RatingProfileDisability.new(disability).most_recent_evaluation || {}
      new(
        type_name: disability[:decn_tn],
        rating_sequence_number: latest_evaluation[:rating_sn],
        rating_issue_reference_id: latest_evaluation[:rba_issue_id], # ok if nil
        disability_date: disability[:dis_dt],
        disability_id: disability[:dis_sn],
        diagnostic_text: latest_evaluation[:dgnstc_txt],
        diagnostic_type: latest_evaluation[:dgnstc_tn],
        diagnostic_code: latest_evaluation[:dgnstc_tc],
        begin_date: latest_evaluation[:begin_dt],
        converted_begin_date: latest_evaluation[:conv_begin_dt],
        original_denial_date: disability[:orig_denial_dt],
        original_denial_indicator: disability[:orig_denial_ind],
        previous_rating_sequence_number: latest_evaluation[:prev_rating_sn],
        profile_date: rating.profile_date,
        promulgation_date: rating.promulgation_date,
        participant_id: rating.participant_id,
        benefit_type: rating.pension? ? :pension : :compensation,
        special_issues: disability[:special_issues],
        rba_contentions_data: disability[:rba_contentions_data]
      )
    end
    # rubocop:enable Metrics/MethodLength

    def deserialize(hash)
      new(hash.merge(special_issues: deserialize_special_issues(hash)))
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def deserialize_special_issues(serialized_hash)
      data = []
      if serialized_hash[:special_issues].present?
        filtered_special_issues = serialized_hash[:special_issues].map do |special_issue|
          special_issue.with_indifferent_access if special_issue.with_indifferent_access[:dis_sn] == serialized_hash[:disability_id] # rubocop:disable Layout/LineLength
        end.compact

        filtered_special_issues.each do |special_issue|
          data << { mst_available: true } if Rating.special_issue_has_mst?(special_issue)

          data << { pact_available: true } if Rating.special_issue_has_pact?(special_issue)
        end
      end

      if serialized_hash[:rba_contentions_data]
        data << { mst_available: true } if Rating.mst_from_contentions_for_rating?(serialized_hash)

        data << { pact_available: true } if Rating.pact_from_contentions_for_rating?(serialized_hash)
      end
      data
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
  end

  def decision_text
    service_connected? ? service_connected_decision_text : not_service_connected_decision_text
  end

  # the decision date is the formal date under which this decision will be grouped in the UI.
  # We currently use promulgation_date to be consistent with RatingIssue, even though that might
  # not be the actual decision date. See effective_date for why.
  def decision_date
    promulgation_date
  end

  def contestable?
    !rating_issue?
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

  # The effective date is what we call the date when the rating decision appears to have been made,
  # even if the official legal date is the promulgation date. Because of the way disability evaluations
  # are presented in the API response from BGS, it's not clear if each evaluation represents a new
  # decision or not. We err on the side of always including each evaluation listed, in order to make sure
  # all issues can be Intaken.
  def effective_date
    effective_start_date_of_original_decision || disability_date
  end

  private

  # the "effective date" is the name we give the original decision date.
  # we have to make educated guesses because there are a variety of "date" attributes
  # on a rating decision and they are not populated consistently.
  def effective_start_date_of_original_decision
    [original_denial_date, converted_begin_date, begin_date].compact.min
  end

  def service_connected_decision_text
    "#{diagnostic_type} (#{diagnostic_text}) is granted."
  end

  def not_service_connected_decision_text
    "#{diagnostic_type} (#{diagnostic_text}) is denied."
  end
end
