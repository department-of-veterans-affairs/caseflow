# frozen_string_literal: true

class RatingAtIssue < Rating
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

    def fetch_in_range(participant_id:, start_date:, end_date:)
      response = BGSService.new.fetch_rating_profiles_in_range(
        participant_id: participant_id,
        start_date: start_date,
        end_date: end_date
      )

      sorted_ratings_from_bgs_response(response)
    end

    def from_bgs_hash(data)
      new(
        participant_id: data[:ptcpnt_vet_id],
        profile_date: data[:prfil_dt],
        promulgation_date: data[:prmlgn_dt]
      )
    end

    private

    def ratings_from_bgs_response(response)
      Array.wrap(response[:rba_profile_list][:rba_profile]).map do |rating_data|
        Rating.from_bgs_hash(rating_data)
      end
    end
  end

  def decisions
    []
  end

  private

  def associated_claims_data
    claim_list = response[:rba_claim_list]
    return [] unless claim_list.present?

    Array.wrap(claim_list).map{ |claim| claim[:rba_claim] }
  end

  def rating_profile

  end
end
