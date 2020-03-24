# frozen_string_literal: true

class PromulgatedRating < Rating
  class NilRatingProfileListError < StandardError
    def ignorable?
      true
    end
  end

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

  def issues
    return [] if rating_profile[:rating_issues].nil?

    [rating_profile[:rating_issues]].flatten.map do |issue_data|
      issue_data[:dgnstc_tc] = diagnostic_codes.dig(issue_data[:dis_sn], :dgnstc_tc)
      RatingIssue.from_bgs_hash(self, issue_data)
    end
  end

  def decisions
    return [] unless FeatureToggle.enabled?(:contestable_rating_decisions, user: RequestStore[:current_user])
    return [] unless rating_profile[:disabilities]

    Array.wrap(rating_profile[:disabilities]).map do |disability|
      RatingDecision.from_bgs_disability(self, disability)
    end
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
    return [] if rating_profile[:associated_claims].nil?

    Array.wrap(rating_profile[:associated_claims])
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
    def fetch_in_range(participant_id:, start_date:, end_date:)
      response = BGSService.new.fetch_ratings_in_range(
        participant_id: participant_id,
        start_date: start_date,
        end_date: end_date
      )

      sorted_ratings_from_bgs_response(response)
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
