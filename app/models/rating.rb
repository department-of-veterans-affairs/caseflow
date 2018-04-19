class Rating
  attr_accessor :participant_id, :profile_date, :promulgation_date

  def issues
    @rating_issues ||= RatingIssue.fetch(rating: self)
  end

  def self.fetch_timely(participant_id: participant_id)

  end
end
