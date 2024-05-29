# frozen_string_literal: true

# Disable :reek:InstanceVariableAssumption
# rubocop:disable Layout/LineLength
# rubocop:disable Lint/UselessAssignment
module Seeds
  class AmaIntake < Base
    def initialize
      file_number_initial_value
    end

    def seed!
      create_veteran_with_no_legacy_appeals_and_many_request_and_decision_issues
      create_veteran_with_legacy_appeals_and_many_request_and_decision_issues
      create_veteran_with_no_legacy_appeals_and_request_issue_with_many_decision_issues
      create_veteran_with_legacy_appeals_and_request_issue_with_many_decision_issues
      create_veteran_with_no_legacy_appeals_and_decision_issue_with_many_request_issues
      create_veteran_with_legacy_appeals_and_decision_issue_with_many_request_issues
      create_veteran_without_request_issues
    end

    private

    # Maintains previous file number values while allowing for reseeding
    def file_number_initial_value
      @file_number ||= 900_000
      # This seed file creates 6 new veterans on each run, 10 is sufficient margin to add more data
      @file_number += 10 while Veteran.find_by(file_number: format("%<n>09d", n: @file_number))
    end

    # Veteran with 420 Request Issues and 360 Decision Issues
    def create_veteran_with_no_legacy_appeals_and_many_request_and_decision_issues
      # Veteran with associated Decision Reviews, Request Issues, and Decision Issues
      veteran = create_veteran

      # 1 Appeal containing 180 Request Issues each with a Decision Issue
      appeal = create_appeal(veteran)
      180.times do
        create_appeal_request_issue(:rating, appeal, veteran, :with_associated_decision_issue)
      end

      # 1 Higher Level Review containing 180 Request Issues each with a Decision Issue
      hlr_epe = create_end_product_establishment(:cleared_hlr_with_veteran_claimant, veteran)
      180.times do
        create_claim_review_request_issue(:rating, hlr_epe, veteran, :with_associated_decision_issue)
      end

      # 1 Supplemental Claim containing 60 Request Issues with no Decision Issues
      supp_epe = create_end_product_establishment(:active_supp_with_dependent_claimant, veteran)
      60.times do
        create_claim_review_request_issue(:nonrating, supp_epe, veteran)
      end
    end

    # Veteran with 5 Legacy Appeals, 420 Request Issues and 360 Decision Issues
    def create_veteran_with_legacy_appeals_and_many_request_and_decision_issues
      # Veteran with associated Legacy Appeals, Decision Reviews, Request Issues, and Decision Issues
      veteran = create_veteran

      # 5 VACOLS Appeals
      5.times do
        create_vacols_appeal(veteran)
      end

      # 1 Appeal containing 180 Request Issues each with a Decision Issue
      appeal = create_appeal(veteran)
      180.times do
        create_appeal_request_issue(:rating, appeal, veteran, :with_associated_decision_issue)
      end

      # 1 Higher Level Review containing 180 Request Issues each with a Decision Issue
      hlr_epe = create_end_product_establishment(:cleared_hlr_with_veteran_claimant, veteran)
      180.times do
        create_claim_review_request_issue(:rating, hlr_epe, veteran, :with_associated_decision_issue)
      end

      # 1 Supplemental Claim containing 60 Request Issues with no Decision Issues
      supp_epe = create_end_product_establishment(:active_supp_with_dependent_claimant, veteran)
      60.times do
        create_claim_review_request_issue(:nonrating, supp_epe, veteran)
      end
    end

    # Veteran with 15 total Request Issues and 82 Decision Issues
    # Each Request Issue contains 1 Decision Issue, except for one outlier containing 68 Decision Issues
    def create_veteran_with_no_legacy_appeals_and_request_issue_with_many_decision_issues
      # Veteran with associated Decision Reviews, Request Issues, and Decision Issues
      veteran = create_veteran

      # 1 Appeal containing 7 Request Issues each with a Decision Issue
      appeal = create_appeal(veteran)
      7.times do
        create_appeal_request_issue(:rating, appeal, veteran, :with_associated_decision_issue)
      end

      # 1 Higher Level Review containing 8 total Request Issues
      # Each Request Issue correlates to a single Decision Issue, except for one outlier correlating to 68 Decision Issues
      hlr_epe = create_end_product_establishment(:cleared_hlr_with_veteran_claimant, veteran)
      7.times do
        create_claim_review_request_issue(:rating, hlr_epe, veteran, :with_associated_decision_issue)
      end
      # Outlier Request Issue with 68 Decision Issues
      create_request_issue_with_many_decision_issues(:nonrating, hlr_epe, veteran, number_of_issues = 68)
    end

    # Veteran with 5 VACOLS Appeals, 15 total Request Issues and 82 Decision Issues
    # Each Request Issue contains 1 Decision Issue, except for one outlier containing 68 Decision Issues
    def create_veteran_with_legacy_appeals_and_request_issue_with_many_decision_issues
      # Veteran with associated Decision Reviews, Request Issues, and Decision Issues
      veteran = create_veteran

      # 5 VACOLS Appeals
      5.times do
        create_vacols_appeal(veteran)
      end

      # 1 Appeal containing 7 Request Issues each with a Decision Issue
      appeal = create_appeal(veteran)
      7.times do
        create_appeal_request_issue(:rating, appeal, veteran, :with_associated_decision_issue)
      end

      # 1 Higher Level Review containing 8 total Request Issues
      # Each Request Issue correlates to a single Decision Issue, except for one outlier correlating to 68 Decision Issues
      hlr_epe = create_end_product_establishment(:cleared_hlr_with_veteran_claimant, veteran)
      7.times do
        create_claim_review_request_issue(:rating, hlr_epe, veteran, :with_associated_decision_issue)
      end
      # Outlier Request Issue with 68 Decision Issues
      create_request_issue_with_many_decision_issues(:nonrating, hlr_epe, veteran, number_of_issues = 68)
    end

    # Veteran with 35 total Request Issues and 5 Decision Issues
    # Each Decision Issue contains 1 Request Issue, except for one outlier containing 31 Request Issues
    def create_veteran_with_no_legacy_appeals_and_decision_issue_with_many_request_issues
      # Veteran with associated Decision Reviews, Request issues, and Decision Issues
      veteran = create_veteran

      # 1 Appeal containing 2 Request Issues each with a Decision Issue
      appeal = create_appeal(veteran)
      2.times do
        create_appeal_request_issue(:rating, appeal, veteran, :with_associated_decision_issue)
      end

      # 1 Higher Level Review containing 3 total Request Issues
      # Each Decision Issue correlates to a single Request Issue, except for one outlier correlating to 31 Request Issues
      hlr_epe = create_end_product_establishment(:cleared_hlr_with_veteran_claimant, veteran)
      2.times do
        create_claim_review_request_issue(:rating, hlr_epe, veteran, :with_associated_decision_issue)
      end
      # Outlier Decision Issue with 31 Request Issues
      create_decision_issue_with_many_request_issues(:nonrating, hlr_epe, veteran, number_of_issues = 31)
    end

    # Veteran with 5 VACOLS Appeals, 35 total Request Issues and 5 Decision Issues
    # Each Decision Issue contains 1 Request Issue, except for one outlier containing 31 Request Issues
    def create_veteran_with_legacy_appeals_and_decision_issue_with_many_request_issues
      # Veteran with associated Decision Reviews, Request issues, and Decision Issues
      veteran = create_veteran

      # 5 VACOLS Appeals
      5.times do
        create_vacols_appeal(veteran)
      end

      # 1 Appeal containing 2 Request Issues each with a Decision Issue
      appeal = create_appeal(veteran)
      2.times do
        create_appeal_request_issue(:rating, appeal, veteran, :with_associated_decision_issue)
      end

      # 1 Higher Level Review containing 3 total Request Issues
      # Each Decision Issue correlates to a single Request Issue, except for one outlier correlating to 31 Request Issues
      hlr_epe = create_end_product_establishment(:cleared_hlr_with_veteran_claimant, veteran)
      2.times do
        create_claim_review_request_issue(:rating, hlr_epe, veteran, :with_associated_decision_issue)
      end
      # Outlier Decision Issue with 31 Request Issues
      create_decision_issue_with_many_request_issues(:nonrating, hlr_epe, veteran, number_of_issues = 31)
    end

    def create_veteran_without_request_issues
      veteran = create_veteran
    end

    def create_veteran
      veteran = create(:veteran, participant_id: format("%<n>09d", n: @file_number), file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      veteran
    end

    def create_appeal(veteran)
      create(:appeal, veteran_file_number: veteran.file_number)
    end

    def create_end_product_establishment(synced_status_and_source, veteran)
      create(:end_product_establishment,
             synced_status_and_source,
             veteran_file_number: veteran.file_number)
    end

    # :reek:LongParameterList
    def create_claim_review_request_issue(rating_or_nonrating_trait, claim_review, veteran, associated_decision_issue_trait = nil)
      if associated_decision_issue_trait
        create(:request_issue,
               rating_or_nonrating_trait,
               associated_decision_issue_trait,
               veteran_participant_id: veteran.participant_id,
               decision_review: claim_review.source,
               end_product_establishment: claim_review)
      else
        create(:request_issue,
               rating_or_nonrating_trait,
               decision_review: claim_review.source,
               veteran_participant_id: veteran.participant_id,
               end_product_establishment: claim_review)
      end
    end

    # :reek:LongParameterList
    def create_appeal_request_issue(rating_trait, appeal, veteran, associated_decision_issue_trait)
      create(:request_issue,
             rating_trait,
             associated_decision_issue_trait,
             veteran_participant_id: veteran.participant_id,
             decision_review: appeal)
    end

    # :reek:LongParameterList
    def create_request_issue_with_many_decision_issues(rating_or_nonrating_trait, hlr_epe, veteran, number_of_issues)
      decision_issues = create_list(:decision_issue,
                                    number_of_issues,
                                    participant_id: veteran.participant_id,
                                    decision_review: hlr_epe.source)
      request_issue = create(:request_issue,
                             rating_or_nonrating_trait,
                             decision_review: hlr_epe.source,
                             end_product_establishment: hlr_epe,
                             veteran_participant_id: veteran.participant_id,
                             decision_issues: decision_issues)
    end

    # :reek:LongParameterList
    def create_decision_issue_with_many_request_issues(rating_or_nonrating_trait, hlr_epe, veteran, number_of_issues)
      request_issues = create_list(:request_issue,
                                   number_of_issues,
                                   rating_or_nonrating_trait,
                                   decision_review: hlr_epe.source,
                                   end_product_establishment: hlr_epe,
                                   veteran_participant_id: veteran.participant_id)
      decision_issue = create(:decision_issue,
                              participant_id: veteran.participant_id,
                              decision_review: hlr_epe.source,
                              request_issues: request_issues)
    end

    def create_vacols_appeal(veteran)
      vacols_appeals = create(:case, bfcorlid: "#{veteran.file_number}S")
    end
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable Lint/UselessAssignment
