# frozen_string_literal: true

class PromulgatedRating < Rating
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

  class << self
    def fetch_in_range(participant_id:, start_date:, end_date:)
      response = BGSService.new.fetch_ratings_in_range(
        participant_id: participant_id,
        start_date: start_date,
        end_date: end_date
      )

      sorted_ratings_from_bgs_response(response)
    rescue Savon::Error
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
      Array.wrap(response[:rating_profile_list][:rating_profile]).map do |rating_data|
        Rating.from_bgs_hash(rating_data)
      end
    end
  end

  def decisions
    return [] unless FeatureToggle.enabled?(:contestable_rating_decisions, user: RequestStore[:current_user])
    return [] unless rating_profile[:disabilities]

    Array.wrap(rating_profile[:disabilities]).map do |disability|
      RatingDecision.from_bgs_disability(self, disability)
    end
  end

  private

  def associated_claims_data
    return [] if rating_profile[:associated_claims].nil?

    Array.wrap(rating_profile[:associated_claims])
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
end
