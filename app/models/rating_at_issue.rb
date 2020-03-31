# frozen_string_literal: true

class RatingAtIssue < Rating
  class << self
    def fetch_in_range(participant_id:, start_date:, end_date:)
      response = BGSService.new.fetch_rating_profiles_in_range(
        participant_id: participant_id,
        start_date: start_date,
        end_date: end_date
      )

      sorted_ratings_from_bgs_response(response: response, start_date: start_date)
    end

    def from_bgs_hash(data)
      new(
        participant_id: data[:ptcpnt_vet_id],
        profile_date: data[:prfl_dt],
        promulgation_date: data[:prmlgn_dt],
        rating_profile: data
      )
    end

    private

    def ratings_from_bgs_response(response)
      ratings = response.dig(:rba_profile_list, :rba_profile)

      if ratings.nil?
        fail NilRatingProfileListError, message: response
      end

      Array.wrap(ratings).map do |rating_data|
        RatingAtIssue.from_bgs_hash(rating_data)
      end
    end
  end

  attr_accessor :rating_profile
end
