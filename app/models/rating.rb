# frozen_string_literal: true

class Rating
  include ActiveModel::Model
  include LatestRatingDisabilityEvaluation

  class NilRatingProfileListError < StandardError
    def ignorable?
      true
    end
  end

  class LockedRatingError < StandardError
    def ignorable?
      true
    end
  end

  class BackfilledRatingError < StandardError
    def ignorable?
      true
    end
  end

  # WARNING: profile_date is a misnomer adopted from BGS terminology.
  # It is a datetime, not a date.
  attr_accessor :participant_id, :profile_date, :promulgation_date
  attr_writer :rating_profile

  ONE_YEAR_PLUS_DAYS = 372.days
  TWO_LIFETIMES_DAYS = 250.years

  def serialize
    Intake::RatingSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def associated_end_products
    associated_claims_data.map do |claim_data|
      EndProduct.new(
        claim_id: claim_data[:clm_id],
        claim_type_code: claim_data[:bnft_clm_tc]
      )
    end
  end

  def issues
    return [] if rating_profile[:rating_issues].nil?

    [rating_profile[:rating_issues]].flatten.map do |issue_data|
      issue_data[:dgnstc_tc] = diagnostic_codes.dig(issue_data[:dis_sn], :dgnstc_tc)
      RatingIssue.from_bgs_hash(self, issue_data)
    end
  end

  def pension?
    associated_claims_data.any? { |ac| ac[:bnft_clm_tc].match(/PMC$/) }
  end

  def decisions
    return [] unless FeatureToggle.enabled?(:contestable_rating_decisions, user: RequestStore[:current_user])
    return [] unless rating_profile[:disabilities]

    Array.wrap(rating_profile[:disabilities]).map do |disability|
      RatingDecision.from_bgs_disability(self, disability)
    end
  end

  private

  def diagnostic_codes
    @diagnostic_codes ||= generate_diagnostic_codes
  end

  def generate_diagnostic_codes
    return {} unless rating_profile[:disabilities]

    Array.wrap(rating_profile[:disabilities]).reduce({}) do |disability_map, disability|
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

  def associated_claims_data
    return [] if rating_profile[:associated_claims].nil?

    [rating_profile[:associated_claims]].flatten
  end

  def fetch_rating_profile
    BGSService.new.fetch_rating_profile(
      participant_id: participant_id,
      profile_date: profile_date
    )
  rescue Savon::Error
    {}
  end

  def rating_profile
    @rating_profile ||= fetch_rating_profile
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

    def fetch_in_range(participant_id:, start_date:, end_date:)
      response = BGSService.new.fetch_ratings_in_range(
        participant_id: participant_id,
        start_date: start_date,
        end_date: end_date
      )

      unsorted = ratings_from_bgs_response(response).select do |rating|
        rating.promulgation_date > start_date
      end

      unsorted.sort_by(&:promulgation_date).reverse
    rescue Savon::Error, BGS::ShareError
      []
    end

    def from_bgs_hash(data)
      new(
        participant_id: data[:comp_id][:ptcpnt_vet_id],
        profile_date: data[:comp_id][:prfil_dt],
        promulgation_date: data[:prmlgn_dt]
      )
    end

    private

    def ratings_from_bgs_response(response)
      if response.dig(:rating_profile_list, :rating_profile).nil?
        reject_reason = response[:reject_reason] || ""
        if reject_reason.include? "Locked Rating"
          fail LockedRatingError, message: response
        elsif reject_reason.include? "Converted or Backfilled Rating"
          fail BackfilledRatingError, message: response
        else
          fail NilRatingProfileListError, message: response
        end
      end

      # If only one rating is returned, we need to convert it to an array
      [response[:rating_profile_list][:rating_profile]].flatten.map do |rating_data|
        Rating.from_bgs_hash(rating_data)
      end
    end
  end
end
