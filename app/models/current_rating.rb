# frozen_string_literal: true

# CurrentRating provides a Rating implementation based on data returned by the BGS endpoint
# rating_profile.find_current_rating_profile_by_ptcpnt_id. Unlike its siblings RatingAtIssue
# and PromulgatedRating, this fetches a single rating per call. Thus, fetch_in_range and
# ratings_from_bgs_response are left unimplemented, and a few other methods aren't used.

class CurrentRating < Rating
  class << self
    def fetch_by_participant_id(participant_id)
      from_bgs_hash(BGSService.new.find_current_rating_profile_by_ptcpnt_id(participant_id))
    rescue BGS::ShareError
      nil
    end

    def from_bgs_hash(data)
      new(
        participant_id: data[:ptcpnt_vet_id],
        profile_date: data[:prfl_dt],
        promulgation_date: data[:prmlgn_dt],
        rating_profile: data
      )
    end
  end
end
