# frozen_string_literal: true

class RatingAtIssue < Rating
  def decisions
    []
  end

  private

  def diagnostic_codes
    @diagnostic_codes ||= generate_diagnostic_codes
  end

  def generate_diagnostic_codes
    return {} unless rating_profile[:disabilities]

    Array.wrap(rating_profile[:disabilities]).reduce({}) do |disability_map, disability|
      disability_time = disability[:dis_dt]

      if disability_map[disability[:dis_sn]].nil? ||
         disability_map[disability[:dis_sn]][:date] < disability_time

        disability_map[disability[:dis_sn]] = {
          dgnstc_tc: get_diagnostic_code(disability),
          date: disability_time
        }
      end

      disability_map
    end
  end

  def get_diagnostic_code(disability)
    self.class.latest_disability_evaluation(disability).dig(:dgnstc_tc)
  end

  def associated_claims_data
    claim_list = response[:rba_claim_list]
    return [] unless claim_list.present?

    Array.wrap(claim_list).map{ |claim| claim[:rba_claim] }
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

    def ratings_from_rating_profile(response)
      Array.wrap(response[:rba_profile_list][:rba_profile]).map do |rating_data|
        Rating.from_bgs_hash(rating_data)
      end
    end

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
      [response[:rating_profile_list][:rating_profile]].flatten.map do |rating_data|
        Rating.from_bgs_hash(rating_data)
      end
    end
  end
end
