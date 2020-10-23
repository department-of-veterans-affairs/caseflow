# frozen_string_literal: true

class PromulgatedRating < Rating
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

      sorted_ratings_from_bgs_response(response: response, start_date: start_date)
    rescue Savon::Error, BGS::ShareError
      []
    end

    def from_bgs_hash(data)
      new(
        participant_id: data.dig(:comp_id, :ptcpnt_vet_id),
        profile_date: data.dig(:comp_id, :prfil_dt),
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
          fail Rating::NilRatingProfileListError, message: response
        end
      end

      Array.wrap(response[:rating_profile_list][:rating_profile]).map do |rating_data|
        PromulgatedRating.from_bgs_hash(rating_data)
      end
    end
  end

  attr_writer :rating_profile

  def rating_profile
    @rating_profile ||= fetch_rating_profile
  end

  private

  def fetch_rating_profile
    BGSService.new.fetch_rating_profile(
      participant_id: participant_id,
      profile_date: profile_date
    )
  rescue Savon::Error
    {}
  rescue BGS::ShareError
    retry_fetching_rating_profile
  end

  # Re-tries fetching the rating profile with the RatingAtIssue service
  def retry_fetching_rating_profile
    ratings_at_issue = RatingAtIssue.fetch_in_range(
      participant_id: participant_id,
      start_date: profile_date,
      end_date: profile_date
    )
    matching_rating = ratings_at_issue.find { |rating| profile_date_matches(rating.profile_date) }
    matching_rating.present? ? matching_rating.rating_profile : {}
  rescue BGS::ShareError, Rating::NilRatingProfileListError => error
    Raven.capture_exception(error)
    {}
  end

  # The profile date is used as a key when fetching a rating by profile date.
  # Profile dates in RatingAtIssue appear to have the same Date/Time stamp, but sometimes disagree by one timezone
  def profile_date_matches(profile_date_to_compare)
    profile_date.strftime("%Y-%m-%d %H:%M:%S") == profile_date_to_compare.strftime("%Y-%m-%d %H:%M:%S")
  end
end
