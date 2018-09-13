class Generators::Rating
  extend Generators::Base

  class << self
    def default_attrs
      {
        participant_id: generate_external_id,
        # we'll do a little more logic to find an open profile date, see: generate_profile_date
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
        ]
      }
    end

    def build(attrs = {})
      attrs = default_attrs.merge(attrs)

      init_fakes(attrs[:participant_id])

      attrs[:profile_date] ||= generate_profile_date(attrs[:participant_id])

      attrs[:issues] = populate_issue_ids(attrs)

      existing_rating = Fakes::BGSService.rating_issue_records[attrs[:participant_id]][attrs[:profile_date]]
      fail "You may not override an existing rating for #{attrs[:profile_date]}" if existing_rating

      Fakes::BGSService.rating_records[attrs[:participant_id]] << bgs_rating_data(attrs)

      Fakes::BGSService.rating_issue_records[attrs[:participant_id]][attrs[:profile_date]] =
        bgs_rating_profile_data(attrs)

      Rating.new(attrs.except(:issues))
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

    def bgs_rating_profile_data(attrs)
      attrs[:issues].map do |issue_data|
        {
          rba_issue_id: issue_data[:reference_id] || generate_external_id,
          decn_txt: issue_data[:decision_text]
        }
      end
    end

    def init_fakes(participant_id)
      Fakes::BGSService.rating_issue_records ||= {}
      Fakes::BGSService.rating_issue_records[participant_id] ||= {}
      Fakes::BGSService.rating_records ||= {}
      Fakes::BGSService.rating_records[participant_id] ||= []
    end

    def generate_profile_date(participant_id)
      dates = (0..10_000).lazy.map { |offset_days| Time.zone.today - offset_days }

      dates.find do |date|
        !Fakes::BGSService.rating_issue_records[participant_id][date]
      end
    end

    def get_prev_issues_count(participant_id)
      Fakes::BGSService.rating_issue_records[participant_id].values.flatten(1).count
    end

    def populate_issue_ids(attrs)
      # gives a unique id to each issue that is tied to a specific participant_id
      prev_count = get_prev_issues_count(attrs[:participant_id])
      attrs[:issues].each_with_index.map do |issue, i|
        issue[:reference_id] ||= "#{attrs[:participant_id]}#{prev_count + i}"
        issue
      end
    end
  end
end
