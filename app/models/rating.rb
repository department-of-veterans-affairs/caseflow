class Rating
  attr_accessor :participant_id, :profile_date, :promulgation_date

  def initialize(attrs)
    # TODO: set attrs
  end

  def issues
    @rating_issues ||= RatingIssue.fetch(rating: self)
  end

  def self.fetch_timely(participant_id:)
    bgs_response = BGSService.new.fetch_ratings_in_range(
        participant_id: participant_id,
        start_date: Time.zone.now - 372.days,
        end_date: Time.zone.now)
    rating_profile = bgs_response[:rating_profile_list][:rating_profile]
    if rating_profile.class == Hash
        rating_profile = [rating_profile]
    end
    rating_profile
  end
end
