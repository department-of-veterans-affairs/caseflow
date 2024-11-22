# frozen_string_literal: true

module Seeds
  class AppealStatusApiTestAppeals < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_file_number_and_ssn
    end

    def seed!
      create_appeals
      create_hlrs
      create_scs
    end

    private

    def initial_file_number_and_ssn
      @file_number ||= 456_000_000
      @ssn ||= 123_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
        @file_number += 1000
        @ssn += 1000
      end
    end

    def create_veteran
      @file_number += 1
      @ssn += 1

      Veteran.find_by_file_number(@ssn) || create(
        :veteran,
        file_number: format("%<n>09d", n: @file_number),
        ssn: format("%<n>09d", n: @ssn)
      )
    end

    def create_appeals
      # :with_request_issues creates appeals with contested rating issues
      # appeals after intake waiting for hearing or evidence submission window
      create(:appeal, :hearing_docket, :with_post_intake_tasks, :with_request_issues, issue_count: 2, veteran: create_veteran)
      create(:appeal, :evidence_submission_docket, :with_post_intake_tasks, :with_request_issues, issue_count: 2)
      # appeals ready for distribution
      create(:appeal, :direct_review_docket, :with_post_intake_tasks, :with_request_issues, issue_count: 2, veteran: create_veteran)
      # appeals awaiting assignment to attorney
      create(:appeal, :direct_review_docket, :assigned_to_judge, :with_request_issues, issue_count: 2, associated_judge: judge_pool.sample, veteran: create_veteran)
      # appeals assigned to an attorney for drafting
      judge = judge_pool.sample
      create(:appeal, :direct_review_docket, :at_attorney_drafting, :with_request_issues, issue_count: 2, associated_judge: judge, associated_attorney: attorney_for_judge(judge), veteran: create_veteran)
      # appeals waiting for judge decision
      judge = judge_pool.sample
      create(:appeal, :direct_review_docket, :at_judge_review, :with_request_issues, issue_count: 2, associated_judge: judge, associated_attorney: attorney_for_judge(judge), veteran: create_veteran)
      # appeals watiing for dispatch
      judge = judge_pool.sample
      create(:appeal, :direct_review_docket, :at_bva_dispatch, :with_request_issues, issue_count: 2, associated_judge: judge, associated_attorney: attorney_for_judge(judge), veteran: create_veteran)
      # appeals dispatched
      judge = judge_pool.sample
      create(:appeal, :direct_review_docket, :dispatched, :with_request_issues, issue_count: 2, associated_judge: judge, associated_attorney: attorney_for_judge(judge), veteran: create_veteran)

      # appeals with nonrating issues
      appeal = create(:appeal, :direct_review_docket, :with_post_intake_tasks, veteran: create_veteran)
      create_list(:request_issue, 2, :nonrating, decision_review: appeal)
      # appeals with unidentified issues
      appeal = create(:appeal, :direct_review_docket, :with_post_intake_tasks, veteran: create_veteran)
      create(:request_issue, :unidentified, decision_review: appeal)
      # appeals with edited issue descriptions
      appeal = create(:appeal, :direct_review_docket, :with_post_intake_tasks, veteran: create_veteran)
      create_list(:request_issue, 2, :nonrating, edited_description: "Edited issue for testing")

      # CAVC remand (for remanded issues)
      create(:appeal, :type_cavc_remand)
    end

    def create_hlrs
      # hlrs after intake
      create(:higher_level_review, :with_request_issue, :create_business_line, benefit_type: "education", veteran: create_veteran)
      # hlrs after decision review task is done
      hlr = create(:higher_level_review, :with_request_issue, :create_business_line, :with_decision, benefit_type: "education", veteran: create_veteran)
      DecisionReviewTask.find_by(appeal: hlr).completed!
    end

    def create_scs
      # scs after intake
      create(:supplemental_claim, :with_request_issue, :create_business_line, benefit_type: "education", veteran: create_veteran)
      # scs after decision review task is done
      sc = create(:supplemental_claim, :with_request_issue, :create_business_line, :with_decision, benefit_type: "education", veteran: create_veteran)
      DecisionReviewTask.find_by(appeal: sc).completed!
    end

    def judge_pool
      @judge_pool = JudgeTeam.all.map(&:judge).compact.select { |j| j.pure_judge_in_vacols? }
    end

    def default_attorney
      @default_attorney = create(:user, :with_vacols_attorney_record)
    end

    def attorney_for_judge(judge)
      JudgeTeam.for_judge(judge)&.attorneys&.sample || default_attorney
    end
  end
end
