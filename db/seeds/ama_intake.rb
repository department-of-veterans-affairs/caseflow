# frozen_string_literal: true

module Seeds
  class AmaIntake < Base
    def initialize
      file_number_initial_value
    end

    # all top level methods
    def seed!
      create_two_veteran_one_with_many_request_and_decision_issues
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
      # First Veteran with associated Decision Reviews, Request issues, and Decision Issues
      veteran_1 = create_veteran

      # 180 Appeals each containing a Request Issue and Decision Issue
      180.times do
        appeal_epe = create_appeal(veteran_1)
        request_issue = create_request_issue(:rating, appeal_epe, veteran_1, :with_rating_decision_issue)
      end

      # 180 Higher Level Reviews each containing a Request Issue and Decision Issue
      180.times do
        hlr_epe = create_end_product_establishment(:cleared_hlr, veteran_1)
        request_issue = create_request_issue(:rating, hlr_epe, veteran_1, :with_rating_decision_issue)
      end

      # 60 Supplemental Claims each containing a Request Issue with no Decision Issues
      60.times do
        supp_epe = create_end_product_establishment(:active_supp, veteran_1)
        request_issue = create_request_issue(:nonrating, supp_epe, veteran_1)
      end

      # Second Veteran with associated Decision Reviews, Request issues, and Decision Issues
      veteran_2 = create_veteran

      # 120 Appeals each containing a Request Issue and Decision Issue
      120.times do
        appeal_epe = create_appeal(veteran)
        request_issue = create_request_issue(:rating, appeal_epe, veteran, :with_rating_decision_issue)
      end

      # 120 Higher Level Reviews each containing a Request Issue and Decision Issue
      120.times do
        hlr_epe = create_end_product_establishment(:cleared_hlr, veteran)
        request_issue = create_request_issue(:rating, hlr_epe, veteran, :with_rating_decision_issue)
      end

      # 40 Supplemental Claims each containing a Request Issue with no Decision Issues
      40.times do
        supp_epe = create_end_product_establishment(:active_supp, veteran)
        request_issue = create_request_issue(:nonrating, supp_epe, veteran)
      end
    end

    # # 2 veterans
    # # 1 RI, 68 DIs.. 15 RIs total
    # # 1 RI, 33 DIs.. 3 RIs total
    # def create_two_veterans_with_request_issue_with_many_decision_issues

    # end

    # # 2 veterans
    # # 1 DI, 31 RIs.. 35 RIs total
    # # 1 DI, 25 RIs.. 50 RIs total
    # def create_two_veterans_with_decision_issue_with_many_request_issues

    # end

    def create_veteran
      veteran = create(:veteran, participant_id: format("%<n>09d", n: @file_number), file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      veteran
    end

    def create_appeal(veteran)
      create(:appeal, veteran_file_number: veteran.file_number)
    end

    def create_end_product_establishment(synced_status, veteran)
      create(:end_product_establishment,
              synced_status,
              veteran_file_number: veteran.file_number,
              claimant_participant_id: veteran.participant_id
            )
    end

    def create_request_issue(rating_or_nonrating_trait, decision_review, veteran, associated_decision_issue_trait = nil)
      if associated_decision_issue_trait
        create(:request_issue,
          rating_or_nonrating_trait,
          associated_decision_issue_trait,
          decision_review: decision_review.is_a?(Appeal) ? decision_review : decision_review.source,
          end_product_establishment: decision_review.is_a?(Appeal) ? nil : decision_review,
          veteran_participant_id: veteran.participant_id
        )
      else
        create(:request_issue,
          rating_or_nonrating_trait,
          decision_review: decision_review.is_a?(Appeal) ? decision_review : decision_review.source,
          end_product_establishment: decision_review.is_a?(Appeal) ? nil : decision_review,
          veteran_participant_id: veteran.participant_id
        )
      end
    end
  end
end
