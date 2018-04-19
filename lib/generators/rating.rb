class Generators::Rating
  extend Generators::Base

  class << self
    def default_attrs
      {
        profile_date: Time.zone.today - 30,
        participant_id: generate_external_id,
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

      Fakes::BGSService.rating_issue_records ||= {}
      Fakes::BGSService.rating_issue_records[attrs[:participant_id]] ||= {}

      existing_rating = Fakes::BGSService.rating_issue_records[attrs[:participant_id]][attrs[:profile_date]] 
      raise "You may not override an existing rating for #{attrs[:profile_date]}" if existing_rating

      Fakes::BGSService.rating_records ||= {}
      Fakes::BGSService.rating_records[attrs[:participant_id]] ||= []
      Fakes::BGSService.rating_records[attrs[:participant_id]] << bgs_rating_data(attrs)

      Fakes::BGSService.rating_issue_records[attrs[:participant_id]][attrs[:profile_date]] =
        bgs_rating_profile_data(attrs)

      Rating.new(attrs)
    end

    private

    def bgs_rating_data(attrs)
      {
        comp_id: {
          prfil_dt: attrs[:profile_date],
          ptcpnt_vet_id: attrs[:participant_id]
        },
        :prmlgn_dt=> attrs[:promulgation_date]
      }
    end

    # 
    def bgs_rating_profile_data(attrs)
      attrs[:issues].map do |issue_data|
        {
          rba_issue_id: issue_data[:rba_issue_id] || generate_external_id,
          decn_txt: issue_data[:decision_text]
        }
      end
    end
  end
end
