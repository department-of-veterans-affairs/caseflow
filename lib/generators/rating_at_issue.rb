# frozen_string_literal: true

class Generators::RatingAtIssue < Generators::Rating
  class << self
    def create_ratings(attrs)
      Fakes::BGSService.store_rating_profile_record(
        attrs[:participant_id],
        attrs[:profile_date],
        bgs_rating_profile_data(attrs)
      )

      RatingAtIssue.from_bgs_hash(bgs_rating_data(attrs))
    end

    private

    def bgs_rating_data(attrs)
      {
        prfl_dt: attrs[:profile_date],
        ptcpnt_vet_id: attrs[:participant_id],
        prmlgn_dt: attrs[:promulgation_date],
        rba_issue_list: bgs_rating_issues_data(attrs),
        disability_list: { disability: [attrs[:disabilities], bgs_rating_decisions_data(attrs)].compact.flatten },
        rba_claim_list: { rba_claim: bgs_associated_claims_data(attrs) }
      }
    end

    def bgs_rating_issues_data(attrs)
      return nil unless attrs[:issues]

      issue_data = attrs[:issues].map do |issue|
        {
          rba_issue_id: issue[:reference_id] || generate_external_id,
          decn_txt: issue[:decision_text],
          rba_issue_contentions: {
            prfl_dt: issue[:profile_date],
            cntntn_id: issue[:contention_reference_id]
          },
          dis_sn: issue[:dis_sn],
          subjct_txt: issue[:subject_text]
        }
      end

      # BGS returns the data not as an array if there is only one issue
      (issue_data.length == 1) ? { rba_issue: issue_data.first } : { rba_issue: issue_data }
    end
  end
end
