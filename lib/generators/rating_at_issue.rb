# frozen_string_literal: true

class Generators::RatingAtIssue < Generators::Rating
  class << self
    def create_ratings(attrs)
      RatingAtIssue.from_bgs_hash(bgs_rating_data(attrs))
    end

    private

    def bgs_rating_data(attrs)
      {
        prfl_dt: attrs[:profile_date],
        ptcpnt_vet_id: attrs[:participant_id],
        prmlgn_dt: attrs[:promulgation_date],
        rba_issue_list: bgs_rating_issues_data(attrs),
        disability_list: [attrs[:disabilities], bgs_rating_decisions_data(attrs)].compact.flatten,
        rba_claim_list: bgs_associated_claims_data(attrs)
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
          dis_sn: issue[:dis_sn]
        }
      end

      # BGS returns the data not as an array if there is only one issue
      (issue_data.length == 1) ? issue_data.first : issue_data
    end
  end
end
