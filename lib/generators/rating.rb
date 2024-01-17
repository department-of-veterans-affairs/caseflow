# frozen_string_literal: true

class Generators::Rating
  extend Generators::Base

  class << self
    DATE_LIST = (0..100).map { |offset_days| (Time.zone.now - offset_days.days).to_date }

    def default_attrs
      {
        participant_id: generate_external_id,
        # we'll do a little more logic to find an open profile date, see: generate_profile_datetime
        profile_date: nil,
        promulgation_date: Time.zone.today - 30,
        issues: [
          {
            decision_text: "Service connection for Emphysema is granted with an evaluation"\
              " of 100 percent effective June 1, 2013."
          },
          {
            decision_text: "Basic eligibility to Dependents' Educational Assistance"\
              " is established from October 1, 2017."
          }
        ],
        decisions: [],
        associated_claims: []
      }
    end

    def build(attrs = {})
      attrs = default_attrs.merge(attrs)

      init_fakes(attrs[:participant_id])

      attrs[:profile_date] ||= generate_profile_datetime(attrs[:participant_id])

      attrs[:issues] = populate_issue_ids(attrs)

      attrs[:decisions] = populate_decision_ids(attrs)

      existing_rating = rating_store.fetch_and_inflate(attrs[:participant_id])[:profiles].try(attrs[:profile_date].to_s)
      fail "You may not override an existing rating for #{attrs[:profile_date]}" if existing_rating

      Fakes::BGSService.store_rating_record(attrs[:participant_id], bgs_rating_data(attrs))

      create_ratings(attrs)
    end

    def create_ratings(*)
      fail Caseflow::Error::MustImplementInSubclass
    end

    private

    def bgs_rating_issues_data(_attrs)
      fail Caseflow::Error::MustImplementInSubclass
    end

    def bgs_rating_profile_data(attrs)
      {
        rating_issues: bgs_rating_issues_data(attrs),
        associated_claims: bgs_associated_claims_data(attrs),
        disabilities: [attrs[:disabilities], bgs_rating_decisions_data(attrs)].compact.flatten
      }
    end

    def bgs_rating_decisions_data(attrs)
      return nil unless attrs[:decisions]

      decisions_data = attrs[:decisions].map do |decision|
        {
          disability_evaluations: {
            rba_issue_id: decision[:rating_issue_reference_id],
            dgnstc_txt: decision[:diagnostic_text],
            dgnstc_tn: decision[:diagnostic_type],
            dgnstc_tc: decision[:diagnostic_code],
            prfl_dt: decision[:profile_date],
            rating_sn: decision[:rating_sequence_number] || generate_external_id
          },
          decn_tn: decision[:type_name],
          dis_sn: decision[:disability_id],
          dis_dt: decision[:disability_date],
          orig_denial_dt: decision[:original_denial_date]
        }
      end

      (decisions_data.length == 1) ? decisions_data.first : decisions_data
    end

    def bgs_associated_claims_data(attrs)
      return nil unless attrs[:associated_claims]

      (attrs[:associated_claims].length == 1) ? attrs[:associated_claims].first : attrs[:associated_claims]
    end

    def rating_store
      @rating_store ||= Fakes::RatingStore.new
    end

    def init_fakes(participant_id)
      rating_store.init_store(participant_id)
    end

    def generate_profile_datetime(participant_id)
      ratings = rating_store.fetch_and_inflate(participant_id) || {}
      DATE_LIST.find { |date| !ratings[:profiles].try(date.to_s) }
    end

    def populate_issue_ids(attrs)
      return unless attrs[:issues]

      # gives a unique id to each issue that is tied to a specific participant_id
      attrs[:issues].map do |issue|
        issue[:reference_id] ||= "#{attrs[:participant_id]}#{generate_external_id}"
        issue
      end
    end

    def populate_decision_ids(attrs)
      return unless attrs[:decisions]

      attrs[:decisions].map do |decision|
        decision[:rating_sequence_number] ||= "#{attrs[:participant_id]}#{generate_external_id}"
        decision
      end
    end
  end
end
