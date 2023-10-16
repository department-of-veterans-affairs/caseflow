# frozen_string_literal: true

# Disable :reek:InstanceVariableAssumption
module Seeds
  class AmaIntake < Base
    def initialize
      file_number_initial_value
    end

    # all top level methods
    def seed!
      # create_two_veterans_with_many_request_and_decision_issues
      # create_two_veterans_with_request_issue_with_many_decision_issues
      create_two_veterans_with_decision_issue_with_many_request_issues
    end

    private

    # Maintains previous file number values while allowing for reseeding
    def file_number_initial_value
      @file_number ||= 900_000
      # This seed file creates 6 new veterans on each run, 10 is sufficient margin to add more data
      @file_number += 10 while Veteran.find_by(file_number: format("%<n>09d", n: @file_number))
    end

    # 1 Veteran with 420 Request Issues and 360 Decision Issues
    # 1 Veteran with 280 Request Issues and 240 Decision Issues
    def create_two_veterans_with_many_request_and_decision_issues
      # First Veteran with associated Decision Reviews, Request Issues, and Decision Issues
      first_veteran = create_veteran

      # 1 Appeal containing 180 Request Issues each with a Decision Issue
      appeal = create_appeal(first_veteran)
      180.times do
        create_appeal_request_issue(:rating, appeal, first_veteran, :with_rating_decision_issue)
      end

      # 1 Higher Level Review containing 180 Request Issues each with a Decision Issue
      hlr_epe = create_end_product_establishment(:cleared_hlr, first_veteran)
      180.times do
        create_claim_review_request_issue(:rating, hlr_epe, first_veteran, :with_rating_decision_issue)
      end

      # 1 Supplemental Claim containing 60 Request Issues with no Decision Issues
      supp_epe = create_end_product_establishment(:active_supp, first_veteran)
      60.times do
        create_claim_review_request_issue(:nonrating, supp_epe, first_veteran)
      end

      # Second Veteran with associated Decision Reviews, Request Issues, and Decision Issues
      second_veteran = create_veteran

      # 1 Appeal containing 120 Request Issues each with a Decision Issue
      appeal = create_appeal(second_veteran)
      120.times do
        create_appeal_request_issue(:rating, appeal, second_veteran, :with_rating_decision_issue)
      end

      # 1 Higher Level Review containing 120 Request Issue each with a Decision Issue
      hlr_epe = create_end_product_establishment(:cleared_hlr, second_veteran)
      120.times do
        create_claim_review_request_issue(:rating, hlr_epe, second_veteran, :with_rating_decision_issue)
      end

      # 1 Supplemental Claim containing 40 Request Issues with no Decision Issues
      supp_epe = create_end_product_establishment(:active_supp, second_veteran)
      40.times do
        create_claim_review_request_issue(:nonrating, supp_epe, second_veteran)
      end
    end

    # 1 Veteran with 15 total Request Issues
    # Each Request Issue contains 1 Decision Issues, except for one outlier containing 68 Decision Issues
    # 1 Veteran with 3 total Request Issues
    # Each Request Issue contains 1 Decision Issues, except for one outlier containing 33 Decision Issues
    def create_two_veterans_with_request_issue_with_many_decision_issues
      # First Veteran with associated Decision Reviews, Request Issues, and Decision Issues
      first_veteran = create_veteran

      # 1 Appeal containing 7 Request Issues each with a Decision Issue
      appeal = create_appeal(first_veteran)
      7.times do
        create_appeal_request_issue(:rating, appeal, first_veteran, :with_rating_decision_issue)
      end

      # 1 Higher Level Review containing 8 total Request Issues
      # Each Request Issue correlates to a single Decision Issue, except for one outlier correlating to 68 Decision Issues
      hlr_epe = create_end_product_establishment(:cleared_hlr, first_veteran)
      7.times do
        create_claim_review_request_issue(:rating, hlr_epe, first_veteran, :with_rating_decision_issue)
      end
      # Outlier Request Issue with 68 Decision Issues
      create_request_issue_with_many_decision_issues(:nonrating, hlr_epe, first_veteran, number_of_issues = 68)

      # Second Veteran with associated Decision Reviews, Request issues, and Decision Issues
      second_veteran = create_veteran

      # 1 Higher Level Review containing 3 total Request Issues
      # Each Request Issue correlates to a single Decision Issue, except for one outlier correlating to 33 Decision Issues
      hlr_epe = create_end_product_establishment(:cleared_hlr, second_veteran)
      2.times do
        create_claim_review_request_issue(:rating, hlr_epe, second_veteran, :with_rating_decision_issue)
      end
      # Outlier Request Issue with 33 Decision Issues
      create_request_issue_with_many_decision_issues(:rating, hlr_epe, second_veteran, number_of_issues = 33)
    end

    # 1 Veteran with 35 total Request Issues
    # Each Decision Issue contains 1 Request Issue, except for one outlier containing 31 Request Issues
    # 1 Veteran with 50 total Request Issues
    # Each Decision Issue contains 1 Request Issue, except for one outlier containing 25 Request Issues
    def create_two_veterans_with_decision_issue_with_many_request_issues
      # First Veteran with associated Decision Reviews, Request issues, and Decision Issues
      first_veteran = create_veteran

      # 1 Appeal containing 17 Request Issues each with a Decision Issue
      appeal = create_appeal(first_veteran)
      17.times do
        create_appeal_request_issue(:rating, appeal, first_veteran, :with_rating_decision_issue)
      end

      # 1 Higher Level Review containing 18 total Request Issues
      # Each Decision Issue correlates to a single Request Issue, except for one outlier correlating to 31 Request Issues
      hlr_epe = create_end_product_establishment(:cleared_hlr, first_veteran)
      17.times do
        create_claim_review_request_issue(:rating, hlr_epe, first_veteran, :with_rating_decision_issue)
      end
      # Outlier Decision Issue with 31 Request Issues
      create_decision_issue_with_many_request_issues(:nonrating, hlr_epe, first_veteran, number_of_issues = 31)

      # Second Veteran with associated Decision Reviews, Request issues, and Decision Issues
      second_veteran = create_veteran

      # 1 Appeal containing 25 Request Issues each with a Decision Issue
      appeal = create_appeal(second_veteran)
      25.times do
        create_appeal_request_issue(:rating, appeal, second_veteran, :with_rating_decision_issue)
      end

      # 1 Higher Level Review containing 25 total Request Issues
      # Each Decision Issue correlates to a single Request Issue, except for one outlier correlating to 31 Request Issues
      hlr_epe = create_end_product_establishment(:cleared_hlr, second_veteran)
      24.times do
        create_claim_review_request_issue(:rating, hlr_epe, second_veteran, :with_rating_decision_issue)
      end
      # Outlier Decision Issue with 25 Request Issues
      create_decision_issue_with_many_request_issues(:nonrating, hlr_epe, second_veteran, number_of_issues = 25)
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
            veteran_file_number: veteran.file_number
            )
    end

    # rubocop:disable Metrics/ParameterLists
    # :reek:LongParameterList
    def create_claim_review_request_issue(rating_or_nonrating_trait, claim_review, veteran, rating_decision_issue_trait = nil)
      if rating_decision_issue_trait
        create(:request_issue,
              rating_or_nonrating_trait,
              rating_decision_issue_trait,
              veteran_participant_id: veteran.participant_id,
              decision_review: claim_review.source,
              end_product_establishment: claim_review
              )
      else
        create(:request_issue,
              rating_or_nonrating_trait,
              decision_review: claim_review.source,
              veteran_participant_id: veteran.participant_id,
              end_product_establishment: claim_review
              )
      end
    end

    # rubocop:disable Metrics/ParameterLists
    # :reek:LongParameterList
    def create_appeal_request_issue(rating_trait, appeal, veteran, rating_decision_issue_trait)
      create(:request_issue,
            rating_trait,
            rating_decision_issue_trait,
            veteran_participant_id: veteran.participant_id,
            decision_review: appeal
            )
    end

    # rubocop:disable Metrics/ParameterLists
    # :reek:LongParameterList
    def create_request_issue_with_many_decision_issues(rating_or_nonrating_trait, hlr_epe, veteran, number_of_issues)
      request_issue = create(:request_issue,
                            rating_or_nonrating_trait,
                            decision_review: hlr_epe.source,
                            end_product_establishment: hlr_epe,
                            veteran_participant_id: veteran.participant_id,
                            )
      decision_issues = create_list(:decision_issue,
                                    number_of_issues,
                                    participant_id: veteran.participant_id,
                                    decision_review: request_issue.decision_review
                                    )
      request_issue.decision_issues << decision_issues
      request_issue.save
    end

    # rubocop:disable Metrics/ParameterLists
    # :reek:LongParameterList
    def create_decision_issue_with_many_request_issues(rating_or_nonrating_trait, hlr_epe, veteran, number_of_issues)
      decision_issue = create(:decision_issue,
                              participant_id: veteran.participant_id,
                              decision_review: hlr_epe.source
                              )
      request_issues = create_list(:request_issue,
                                    number_of_issues,
                                    rating_or_nonrating_trait,
                                    decision_review: hlr_epe.source,
                                    end_product_establishment: hlr_epe,
                                    veteran_participant_id: veteran.participant_id
                                  )
      decision_issue.request_issues << request_issues
      decision_issue.save
    end

  end
end
