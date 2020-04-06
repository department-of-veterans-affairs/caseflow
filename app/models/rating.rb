# frozen_string_literal: true

class Rating
  include ActiveModel::Model
  include LatestRatingDisabilityEvaluation

  ONE_YEAR_PLUS_DAYS = 372.days
  TWO_LIFETIMES_DAYS = 250.years

  class NilRatingProfileListError < StandardError
    def ignorable?
      true
    end
  end

  class << self
    def fetch_all(participant_id)
      fetch_timely(participant_id: participant_id, from_date: (Time.zone.today - TWO_LIFETIMES_DAYS))
    end

    def fetch_timely(participant_id:, from_date:)
      fetch_in_range(
        participant_id: participant_id,
        start_date: from_date - ONE_YEAR_PLUS_DAYS,
        end_date: Time.zone.today
      )
    end

    def fetch_in_range(*)
      fail Caseflow::Error::MustImplementInSubclass
    end

    def sorted_ratings_from_bgs_response(response:, start_date:)
      unsorted = ratings_from_bgs_response(response).select do |rating|
        rating.promulgation_date > start_date
      end

      unsorted.sort_by(&:promulgation_date).reverse
    end

    def from_bgs_hash(_data)
      fail Caseflow::Error::MustImplementInSubclass
    end
  end

  # WARNING: profile_date is a misnomer adopted from BGS terminology.
  # It is a datetime, not a date.
  attr_accessor :participant_id, :profile_date, :promulgation_date, :rating_profile

  def serialize
    Intake::RatingSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def issues
    issues_data = Array.wrap(rating_profile[:rating_issues] || rating_profile.dig(:rba_issue_list, :rba_issue))

    issues_data.map do |issue_data|
      issue_data[:dgnstc_tc] = diagnostic_codes.dig(issue_data[:dis_sn], :dgnstc_tc)
      RatingIssue.from_bgs_hash(self, issue_data)
    end
  end

  def decisions
    return [] unless FeatureToggle.enabled?(:contestable_rating_decisions, user: RequestStore[:current_user])

    disability_data = Array.wrap(rating_profile[:disabilities] || rating_profile.dig(:disability_list, :disability))

    disability_data.map do |disability|
      RatingDecision.from_bgs_disability(self, disability)
    end
  end

  def associated_end_products
    associated_claims_data.map do |claim_data|
      EndProduct.new(
        claim_id: claim_data[:clm_id],
        claim_type_code: claim_data[:bnft_clm_tc]
      )
    end
  end

  def pension?
    associated_claims_data.any? { |ac| ac[:bnft_clm_tc].match(/PMC$/) }
  end

  private

  def ratings_from_bgs_response(_response)
    fail Caseflow::Error::MustImplementInSubclass
  end

  def associated_claims_data
    associated_claims = rating_profile[:associated_claims] || rating_profile.dig(:rba_claim_list, :rba_claim)

    Array.wrap(associated_claims)
  end

  def diagnostic_codes
    @diagnostic_codes ||= generate_diagnostic_codes
  end

  def generate_diagnostic_codes
    disability_data = Array.wrap(rating_profile[:disabilities] || rating_profile.dig(:disability_list, :disability))

    return {} if disability_data.blank?

    Array.wrap(disability_data).reduce({}) do |disability_map, disability|
      disability_time = disability[:dis_dt]

      if disability_map[disability[:dis_sn]].nil? ||
         disability_map[disability[:dis_sn]][:date] < disability_time

        disability_map[disability[:dis_sn]] = {
          dgnstc_tc: get_diagnostic_code(disability),
          date: disability_time
        }
      end

      disability_map
    end
  end

  def get_diagnostic_code(disability)
    self.class.latest_disability_evaluation(disability).dig(:dgnstc_tc)
  end
end
