class Generators::Rating
  extend Generators::Base

  class << self
    DATE_LIST = (0..100).map { |offset_days| Time.zone.now - offset_days.days }

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
        associated_claims: []
      }
    end

    def build(attrs = {})
      attrs = default_attrs.merge(attrs)

      init_fakes(attrs[:participant_id])

      attrs[:profile_date] ||= generate_profile_datetime(attrs[:participant_id])

      attrs[:issues] = populate_issue_ids(attrs)

      existing_rating = Fakes::BGSService.rating_profile_records[attrs[:participant_id]][attrs[:profile_date]]
      fail "You may not override an existing rating for #{attrs[:profile_date]}" if existing_rating

      Fakes::BGSService.rating_records[attrs[:participant_id]] << bgs_rating_data(attrs)

      Fakes::BGSService.rating_profile_records[attrs[:participant_id]][attrs[:profile_date]] =
        bgs_rating_profile_data(attrs)

      Rating.new(attrs.except(:issues, :associated_claims))
    end

    private

    def bgs_rating_data(attrs)
      {
        comp_id: {
          prfil_dt: attrs[:profile_date],
          ptcpnt_vet_id: attrs[:participant_id]
        },
        prmlgn_dt: attrs[:promulgation_date]
      }
    end

    def bgs_rating_issues_data(attrs)
      return nil unless attrs[:issues]

      issue_data = attrs[:issues].map do |issue|
        {
          rba_issue_id: issue[:reference_id] || generate_external_id,
          decn_txt: issue[:decision_text],
          rba_issue_contentions: {
            prfil_dt: issue[:profile_date],
            cntntn_id: issue[:contention_reference_id]
          }
        }
      end

      # BGS returns the data not as an array if there is only one issue
      (issue_data.length == 1) ? issue_data.first : issue_data
    end

    def bgs_associated_claims_data(attrs)
      return nil unless attrs[:associated_claims]

      (attrs[:associated_claims].length == 1) ? attrs[:associated_claims].first : attrs[:associated_claims]
    end

    def bgs_rating_profile_data(attrs)
      {
        rating_issues: bgs_rating_issues_data(attrs),
        associated_claims: bgs_associated_claims_data(attrs)
      }
    end

    def init_fakes(participant_id)
      Fakes::BGSService.rating_profile_records ||= {}
      Fakes::BGSService.rating_profile_records[participant_id] ||= {}
      Fakes::BGSService.rating_records ||= {}
      Fakes::BGSService.rating_records[participant_id] ||= []
    end

    def generate_profile_datetime(participant_id)
      DATE_LIST.find do |date|
        !Fakes::BGSService.rating_profile_records[participant_id][date]
      end
    end

    def populate_issue_ids(attrs)
      return unless attrs[:issues]
      # gives a unique id to each issue that is tied to a specific participant_id
      attrs[:issues].map do |issue|
        issue[:reference_id] ||= "#{attrs[:participant_id]}#{generate_external_id}"
        issue
      end
    end
  end
end
