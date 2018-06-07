class Rating
  include ActiveModel::Model

  attr_accessor :participant_id, :profile_date, :promulgation_date

  TIMELY_DAYS = 372.days

  def issues
    @issues ||= fetch_issues
  end

  # If you change this method, you will need
  # to clear cache in prod for your changes to
  # take effect immediately.
  # See Veteran#cached_serialized_timely_ratings.
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

    [response[:rating_issues]].flatten.map do |issue_data|
      RatingIssue.from_bgs_hash(issue_data)
    end
  end

  class << self
    def fetch_timely(participant_id:)
      response = BGSService.new.fetch_ratings_in_range(
        participant_id: v.participant_id,
        start_date: Time.zone.today - 368,
        end_date: Time.zone.today
      )

      unsorted = ratings_from_bgs_response(response).select do |rating|
        rating.promulgation_date > (Time.zone.today - 372)
      end

      unsorted.sort_by(&:promulgation_date).reverse
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
      # If only one rating is returned, we need to convert it to an array
      [response[:rating_profile_list][:rating_profile]].flatten.map do |rating_data|
        Rating.from_bgs_hash(rating_data)
      end
    end
  end
end
