class Rating
  include ActiveModel::Model

  class NilRatingProfileListError < StandardError; end

  # WARNING: profile_date is a misnomer adopted from BGS terminology.
  # It is a datetime, not a date.
  attr_accessor :participant_id, :profile_date, :promulgation_date

  ONE_YEAR_PLUS_DAYS = 372.days
  TWO_LIFETIMES_DAYS = 250.years

  def issues
    @issues ||= fetch_issues
  end

  # If you change this method, you will need
  # to clear cache in prod for your changes to
  # take effect immediately.
  # See DecisionReview#cached_serialized_timely_ratings.
  def ui_hash
    {
      participant_id: participant_id,
      profile_date: profile_date,
      promulgation_date: promulgation_date,
      issues: issues.map(&:ui_hash)
    }
  end

  private

  def fetch_issues
    response = BGSService.new.fetch_rating_profile(
      participant_id: participant_id,
      profile_date: profile_date
    )

    return [] if response[:rating_issues].nil?

    [response[:rating_issues]].flatten.map do |issue_data|
      RatingIssue.from_bgs_hash(self,
                                issue_data.merge(
                                  promulgation_date: promulgation_date,
                                  participant_id: participant_id,
                                  profile_date: profile_date
                                ))
    end
  rescue Savon::Error
    []
  end

  class << self
    def fetch_all(participant_id)
      fetch_timely(participant_id: participant_id, from_date: (Time.zone.today - TWO_LIFETIMES_DAYS))
    end

    def fetch_timely(participant_id:, from_date:)
      start_date = from_date - ONE_YEAR_PLUS_DAYS
      response = BGSService.new.fetch_ratings_in_range(
        participant_id: participant_id,
        start_date: start_date,
        end_date: Time.zone.today
      )

      unsorted = ratings_from_bgs_response(response).select do |rating|
        rating.promulgation_date > start_date
      end

      unsorted.sort_by(&:promulgation_date).reverse
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
        fail NilRatingProfileListError, message: response
      end
      # If only one rating is returned, we need to convert it to an array
      [response[:rating_profile_list][:rating_profile]].flatten.map do |rating_data|
        Rating.from_bgs_hash(rating_data)
      end
    end
  end
end
