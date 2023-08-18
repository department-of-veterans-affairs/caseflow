# frozen_string_literal: true

module Seeds
  class AdditionalRemandedAppeals < Base
    def initialize
      initial_id_values
      @ama_appeals = []
    end

    def seed!
      create_request_issues
      create_ama_appeals_decision_ready_es
      create_ama_appeals_decision_ready_hr
      create_ama_appeals_decision_ready_dr
      create_ama_appeals_ready_to_dispatch_remanded_es
      create_ama_appeals_ready_to_dispatch_remanded_hr
      create_ama_appeals_ready_to_dispatch_remanded_dr
      create_ama_appeals_ready_to_dispatch_remanded_multiple_es
      create_ama_appeals_ready_to_dispatch_remanded_multiple_hr
      create_ama_appeals_ready_to_dispatch_remanded_multiple_dr
    end

    private

    def initial_id_values
      @file_number ||= 500_000_000
      @participant_id ||= 900_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1)) ||
            VACOLS::Correspondent.find_by(ssn: format("%<n>09d", n: @file_number + 1))
        @file_number += 2000
        @participant_id += 2000
      end
    end

    def create_veteran(options = {})
      @file_number += 1
      @participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      }
      create(:veteran, params.merge(options))
    end

    def create_request_issues
      create_allowed_request_issues
      create_remanded_request_issues
    end

    def create_allowed_request_issues
      nca = BusinessLine.find_by(name: "National Cemetery Administration")
      description = "Service connection for pain disorder is granted with an evaluation of 50\% effective August 1 2020"
      notes = "Pain disorder with 80\% evaluation per examination"

      3.times do |index|
        board_grant_task = create(:board_grant_effectuation_task,
                                  status: "assigned",
                                  assigned_to: nca)

        request_issues = create_list(:request_issue, 3,
                                     :nonrating,
                                     contested_issue_description: "#{index} #{description}",
                                     notes: "#{index} #{notes}",
                                     benefit_type: nca.url,
                                     decision_review: board_grant_task.appeal)

        request_issues.each do |request_issue|
          # create matching decision issue
          create(
            :decision_issue,
            :nonrating,
            disposition: "allowed",
            decision_review: board_grant_task.appeal,
            request_issues: [request_issue],
            rating_promulgation_date: 2.months.ago,
            benefit_type: request_issue.benefit_type
          )
        end
      end
    end

    def create_remanded_request_issues
      comp = BusinessLine.find_by(name: "Compensation")
      description = "Service connection for pain disorder is granted with an evaluation of 60\% effective February 1 2021"
      notes = "Pain disorder with 90\% evaluation per examination"

      3.times do |index|
        board_grant_task = create(:board_grant_effectuation_task,
                                  status: "assigned",
                                  assigned_to: comp)

        request_issues = create_list(:request_issue, 3,
                                     :nonrating,
                                     contested_issue_description: "#{index} #{description}",
                                     notes: "#{index} #{notes}",
                                     benefit_type: comp.url,
                                     decision_review: board_grant_task.appeal)

        decision_issue = create_list(decision_reason: "No notice sent",
                                     decision_reason: "Incorrect notice sent",
                                     decision_reason: "Legally inadequate notice",
                                     decision_reason: "VA records",
                                     decision_reason: "Private records",
                                     decision_reason: "Service personnel records",
                                     decision_reason: "Service treatment records",
                                     decision_reason: "Other government records",
                                     decision_reason: "Medical examinations",
                                     decision_reason: "Medical opinions",
                                     decision_reason: "Advisory medical opinion",
                                     decision_reason: "Other due process deficiency",
#New Remand Reasons not implemented yet
=begin
                                     decision_reason: "No medical examination",
                                     decision_reason: "Inadequate medical examination",
                                     decision_reason: "No medical opinion",
                                     decision_reason: "Inadequate medical opinion",
                                     decision_reason: "Advisory medical opinion",
                                     decision_reason: "Inextricably intertwined",
                                     decision_reason: "Error satisfying regulatory or statutory duty",
                                     decision_reason: "Other",

=end
        )

        request_issues.each do |request_issue|
          # create matching decision issue
          create(
            :decision_issue,
            :nonrating,
            disposition: "remanded",
            decision_review: board_grant_task.appeal,
            request_issues: [request_issue],
            rating_promulgation_date: 1.months.ago,
            benefit_type: request_issue.benefit_type
          )
        end
      end
    end

    def create_ama_appeals_decision_ready_es
      Timecop.travel(45.days.ago)
      appeal = create(:appeal,
                      :evidence_submission_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      associated_judge: User.find_by_css_id("BVAAABSHIRE"),
                      associated_attorney: User.find_by_css_id("BVASCASPER"),
                      issue_count: 3,
                      veteran: create_veteran)
      Timecop.return
    end

    def create_ama_appeals_decision_ready_hr
      1.times.do
      Timecop.travel(45.days.ago)
      appeal = create(:appeal,
                      :hearing_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      associated_judge: User.find_by_css_id("BVAAABSHIRE"),
                      associated_attorney: User.find_by_css_id("BVASCASPER"),
                      issue_count: 3,
                      veteran: create_veteran)
      Timecop.return
    end

    def create_ama_appeals_decision_ready_dr
      Timecop.travel(45.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      associated_judge: User.find_by_css_id("BVAAABSHIRE"),
                      associated_attorney: User.find_by_css_id("BVASCASPER"),
                      issue_count: 3,
                      veteran: create_veteran)
      Timecop.return
    end

    def create_ama_appeals_ready_to_dispatch_remanded_es
      Timecop.travel(30.days.ago)
      appeal = create(:appeal,
                      :evidence_submission_docket,
                      :with_request_issues,
                      :at_judge_review,
                      associated_judge: User.find_by_css_id("BVAAABSHIRE"),
                      associated_attorney: User.find_by_css_id("BVASCASPER"),
                      issue_count: 3,
                      veteran: create_veteran)
      Timecop.return
    end

    def create_ama_appeals_ready_to_dispatch_remanded_hr
      Timecop.travel(30.days.ago)
      appeal = create(:appeal,
                      :hearing_docket,
                      :with_request_issues,
                      :at_judge_review,
                      associated_judge: User.find_by_css_id("BVAAABSHIRE"),
                      associated_attorney: User.find_by_css_id("BVASCASPER"),
                      issue_count: 3,
                      veteran: create_veteran)
      Timecop.return
    end

    def create_ama_appeals_ready_to_dispatch_remanded_dr
      Timecop.travel(30.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_judge_review,
                      associated_judge: User.find_by_css_id("BVAAABSHIRE"),
                      associated_attorney: User.find_by_css_id("BVASCASPER"),
                      issue_count: 3,
                      veteran: create_veteran)
      Timecop.return
    end

    def create_ama_appeals_ready_to_dispatch_remanded_multiple_es
      Timecop.travel(15.days.ago)
      appeal = create(:appeal,
                      :evidence_submission_docket,
                      :with_request_issues,
                      :at_judge_review,
                      associated_judge: User.find_by_css_id("BVAAABSHIRE"),
                      associated_attorney: User.find_by_css_id("BVASCASPER"),
                      issue_count: 3,
                      veteran: create_veteran)
      Timecop.return
    end

    def create_ama_appeals_ready_to_dispatch_remanded_multiple_hr
      Timecop.travel(15.days.ago)
      appeal = create(:appeal,
                      :hearing_docket,
                      :with_request_issues,
                      :at_judge_review,
                      associated_judge: User.find_by_css_id("BVAAABSHIRE"),
                      associated_attorney: User.find_by_css_id("BVASCASPER"),
                      issue_count: 3,
                      veteran: create_veteran)
      Timecop.return
    end

    def create_ama_appeals_ready_to_dispatch_remanded_multiple_dr
      Timecop.travel(15.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_judge_review,
                      associated_judge: User.find_by_css_id("BVAAABSHIRE"),
                      associated_attorney: User.find_by_css_id("BVASCASPER"),
                      issue_count: 3,
                      veteran: create_veteran)
      Timecop.return
    end
