# frozen_string_literal: true

class Rating
  include ActiveModel::Model
  include LatestRatingDisabilityEvaluation

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

  def pension?
    associated_claims_data.any? { |ac| ac[:bnft_clm_tc].match(/PMC$/) }
  end

  def associated_claims_data
    fail Caseflow::Error::MustImplementInSubclass
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

    def sorted_ratings_from_bgs_response(response)
      unsorted = ratings_from_bgs_response(response).select do |rating|
        rating.promulgation_date > start_date
      end

      unsorted.sort_by(&:promulgation_date).reverse
    end
  end
end
