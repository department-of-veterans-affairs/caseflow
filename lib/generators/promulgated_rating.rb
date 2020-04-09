# frozen_string_literal: true

class Generators::PromulgatedRating < Generators::Rating
  class << self
    def create_ratings(attrs)
      Fakes::BGSService.store_rating_profile_record(
        attrs[:participant_id],
        attrs[:profile_date],
        bgs_rating_profile_data(attrs)
      )

      PromulgatedRating.new(attrs.except(:issues, :decisions, :associated_claims, :disabilities))
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
          },
          dis_sn: issue[:dis_sn]
        }
      end

      # BGS returns the data not as an array if there is only one issue
      (issue_data.length == 1) ? issue_data.first : issue_data
    end

    def bgs_rating_profile_data(attrs)
      {
        rating_issues: bgs_rating_issues_data(attrs),
        associated_claims: bgs_associated_claims_data(attrs),
        disabilities: [attrs[:disabilities], bgs_rating_decisions_data(attrs)].compact.flatten
      }
    end
  end
end
