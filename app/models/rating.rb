class Rating
  include ActiveModel::Model

  attr_accessor :participant_id, :profile_date, :promulgation_date

  TIMELY_DAYS = 372.days

  class << self
    def fetch_timely(participant_id:)
      response = BGSService.new.fetch_ratings_in_range(
        participant_id: participant_id,
        start_date: Time.zone.today - TIMELY_DAYS,
        end_date: Time.zone.today
      )

      ratings_from_bgs_response(response).select do |rating|
        rating.promulgation_date > (Time.zone.today - 372)
      end
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
