# frozen_string_literal: true

module Seeds
  class RemandedAmaAppeals < Base
    def initialize
      initial_id_values
    end

    def seed!
      create_ama_appeals_decision_ready_es(attorney)
      create_ama_appeals_decision_ready_hr(attorney)
      create_ama_appeals_decision_ready_dr(attorney)
      create_ama_appeals_decision_ready_es(attorney2)
      create_ama_appeals_decision_ready_hr(attorney2)
      create_ama_appeals_decision_ready_dr(attorney2)
      create_ama_appeals_decision_ready_es(attorney3)
      create_ama_appeals_decision_ready_hr(attorney3)
      create_ama_appeals_decision_ready_dr(attorney3)
      create_ama_appeals_ready_to_dispatch_remanded_es(attorney)
      create_ama_appeals_ready_to_dispatch_remanded_hr(attorney)
      create_ama_appeals_ready_to_dispatch_remanded_dr(attorney)
      create_ama_appeals_ready_to_dispatch_remanded_multiple_es(attorney)
      create_ama_appeals_ready_to_dispatch_remanded_multiple_hr(attorney)
      create_ama_appeals_ready_to_dispatch_remanded_multiple_dr(attorney)
    end

    private

    def initial_id_values
      @file_number ||= 500_000_000
      @participant_id ||= 900_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
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

    def judge
      @judge ||= User.find_by_css_id("BVAAABSHIRE")
    end

    def attorney
      @attorney ||= User.find_by_css_id("BVASCASPER1")
    end

    def attorney2
      @attorney2 ||= User.find_by_css_id("BVASRITCHIE")
    end

    def attorney3
      @attorney3 ||= User.find_by_css_id("BVARDUBUQUE")
    end

    def decision_reason_remand_list
      [
        "no_notice_sent",
        "incorrect_notice_sent",
        "legally_inadequate_notice",
        "va_records",
        "private_records",
        "service_personnel_records",
        "service_treatment_records",
        "other_government_records",
        "medical_examinations",
        "medical_opinions",
        "no_medical_examination",
        "inadequate_medical_examination",
        "no_medical_opinion",
        "inadequate_medical_opinion",
        "advisory_medical_opinion",
        "inextricably_intertwined",
        "error_satisfying_regulatory_or_statutory_duty",
        "other"
      ]
    end

    def create_ama_remand_reason_variable(remand_code)
      [create(:ama_remand_reason, code: remand_code)]
    end


    def create_allowed_request_issue_no_decision_1(appeal)
      nca = BusinessLine.find_by(name: "National Cemetery Administration")
      description = "Service connection for pain disorder is granted with an evaluation of 25\% effective August 1 2020"
      notes = "Pain disorder with 25\% evaluation per examination"

      board_grant_task = create(:board_grant_effectuation_task,
                                  status: "assigned",
                                  assigned_to: nca,
                                  appeal: appeal)

      request_issues = create_list(:request_issue, 1,
                                    :nonrating,
                                    contested_issue_description: "#{description}",
                                    notes: "#{notes}",
                                    benefit_type: nca.url,
                                    decision_review: board_grant_task.appeal)
    end

    def create_allowed_request_issue_no_decision_2(appeal)
      education = BusinessLine.find_by(name: "Education")
      description = "Service connection for pain disorder is granted with an evaluation of 50\% effective August 2 2021"
      notes = "Pain disorder with 50\% evaluation per examination"

      board_grant_task = create(:board_grant_effectuation_task,
                                status: "assigned",
                                assigned_to: education,
                                appeal: appeal)

      request_issues = create_list(:request_issue, 1,
                                    :nonrating,
                                    contested_issue_description: "#{description}",
                                    notes: "#{notes}",
                                    benefit_type: education.url,
                                    decision_review: board_grant_task.appeal)
    end

    def create_allowed_request_issue_no_decision_3(appeal)
      fiduciary = BusinessLine.find_by(name: "Fiduciary")
      description = "Service connection for pain disorder is granted with an evaluation of 1\% effective August 3 2021"
      notes = "Pain disorder with 1\% evaluation per examination"

      board_grant_task = create(:board_grant_effectuation_task,
                                status: "assigned",
                                assigned_to: fiduciary,
                                appeal: appeal)

      request_issues = create_list(:request_issue, 1,
                                    :nonrating,
                                    contested_issue_description: "#{description}",
                                    notes: "#{notes}",
                                    benefit_type: fiduciary.url,
                                    decision_review: board_grant_task.appeal)
    end


    def create_allowed_request_issue_1(appeal)
      nca = BusinessLine.find_by(name: "National Cemetery Administration")
      description = "Service connection for pain disorder is granted with an evaluation of 25\% effective August 1 2020"
      notes = "Pain disorder with 25\% evaluation per examination"

      board_grant_task = create(:board_grant_effectuation_task,
                                  status: "assigned",
                                  assigned_to: nca,
                                  appeal: appeal)

      request_issues = create_list(:request_issue, 1,
                                    :nonrating,
                                    contested_issue_description: "#{description}",
                                    notes: "#{notes}",
                                    benefit_type: nca.url,
                                    decision_review: board_grant_task.appeal)

      request_issues.each do |request_issue|
        # create matching decision issue
        create(:decision_issue,
          :nonrating,
          disposition: "allowed",
          decision_review: board_grant_task.appeal,
          request_issues: [request_issue],
          rating_promulgation_date: 2.months.ago,
          benefit_type: request_issue.benefit_type)
      end
    end

    def create_allowed_request_issue_2(appeal)
      education = BusinessLine.find_by(name: "Education")
      description = "Service connection for pain disorder is granted with an evaluation of 50\% effective August 2 2021"
      notes = "Pain disorder with 50\% evaluation per examination"

      board_grant_task = create(:board_grant_effectuation_task,
                                status: "assigned",
                                assigned_to: education,
                                appeal: appeal)

      request_issues = create_list(:request_issue, 1,
                                    :nonrating,
                                    contested_issue_description: "#{description}",
                                    notes: "#{notes}",
                                    benefit_type: education.url,
                                    decision_review: board_grant_task.appeal)

      request_issues.each do |request_issue|
        # create matching decision issue
        create(:decision_issue,
          :nonrating,
          disposition: "allowed",
          decision_review: board_grant_task.appeal,
          request_issues: [request_issue],
          rating_promulgation_date: 1.month.ago,
          benefit_type: request_issue.benefit_type)
      end
    end

    def create_remanded_request_issue_1(appeal, num)
      vha = BusinessLine.find_by(name: "Veterans Health Administration")
      description = "Service connection for pain disorder is granted with an evaluation of 75\% effective February 3 2021"
      notes = "Pain disorder with 75\% evaluation per examination"

      board_grant_task = create(:board_grant_effectuation_task,
                                status: "assigned",
                                assigned_to: vha,
                                appeal: appeal)

      request_issues = create_list(:request_issue, 1,
                                   :nonrating,
                                   contested_issue_description: "#{description}",
                                   notes: "#{notes}",
                                   benefit_type: vha.url,
                                   decision_review: board_grant_task.appeal)

      request_issues.each do |request_issue|
        # create matching decision issue
        create(:decision_issue,
          :nonrating,
          remand_reasons: create_ama_remand_reason_variable(decision_reason_remand_list[num]),
          decision_review: board_grant_task.appeal,
          request_issues: [request_issue],
          rating_promulgation_date: 1.month.ago,
          benefit_type: request_issue.benefit_type)
      end
    end

    def create_remanded_request_issue_2(appeal, num)
      insurance = BusinessLine.find_by(name: "Insurance")
      description = "Service connection for pain disorder is granted with an evaluation of 100\% effective February 4 2021"
      notes = "Pain disorder with 100\% evaluation per examination"

      board_grant_task = create(:board_grant_effectuation_task,
                                status: "assigned",
                                assigned_to: insurance,
                                appeal: appeal)

      request_issues = create_list(:request_issue, 1,
                                    :nonrating,
                                    contested_issue_description: "#{description}",
                                    notes: "#{notes}",
                                    benefit_type: insurance.url,
                                    decision_review: board_grant_task.appeal)

      request_issues.each do |request_issue|
        # create matching decision issue
        create(:decision_issue,
          :nonrating,
          remand_reasons: create_ama_remand_reason_variable(decision_reason_remand_list[num]),
          disposition: "remanded",
          decision_review: board_grant_task.appeal,
          request_issues: [request_issue],
          rating_promulgation_date: 1.month.ago,
          benefit_type: request_issue.benefit_type)
      end
    end


    def link_allowed_request_issues_no_decision(appeal)
      create_allowed_request_issue_no_decision_1(appeal)
      create_allowed_request_issue_no_decision_2(appeal)
      create_allowed_request_issue_no_decision_3(appeal)
    end

    def link_with_single_remand_request_issues(appeal, num)
      create_allowed_request_issue_1(appeal)
      create_allowed_request_issue_2(appeal)
      create_remanded_request_issue_1(appeal, num)
    end

    def link_with_multiple_remand_request_issues(appeal, num)
      create_allowed_request_issue_1(appeal)
      create_allowed_request_issue_2(appeal)
      create_remanded_request_issue_1(appeal, num)
      create_remanded_request_issue_2(appeal, num)
    end

    #Appeals Ready for Decision - Attorney Step
    #Evidence Submission
    def create_ama_appeals_decision_ready_es(attorney)
      Timecop.travel(30.days.ago)
        15.times do
          appeal = create(:appeal,
                          :evidence_submission_docket,
                          :at_attorney_drafting,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
          link_allowed_request_issues_no_decision(appeal)
        end
      Timecop.return
    end

    #Hearing
    def create_ama_appeals_decision_ready_hr(attorney)
      Timecop.travel(90.days.ago)
        15.times do
          appeal = create(:appeal,
                          :hearing_docket,
                          :at_attorney_drafting,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
          link_allowed_request_issues_no_decision(appeal)
        end
      Timecop.return
    end

    #Direct Review
    def create_ama_appeals_decision_ready_dr(attorney)
      Timecop.travel(60.days.ago)
        15.times do
          appeal = create(:appeal,
                          :direct_review_docket,
                          :at_attorney_drafting,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
          link_allowed_request_issues_no_decision(appeal)
        end
      Timecop.return
    end

    #Appeals Ready for Decision with 1 Remand
    #Evidence Submission
    def create_ama_appeals_ready_to_dispatch_remanded_es(attorney)
      Timecop.travel(35.days.ago)
       (0..17).each do |num|
          appeal = create(:appeal,
                          :evidence_submission_docket,
                          :at_judge_review,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
          link_with_single_remand_request_issues(appeal, num)
        end
      Timecop.return
    end

    #Hearing
    def create_ama_appeals_ready_to_dispatch_remanded_hr(attorney)
      Timecop.travel(95.days.ago)
       (0..17).each do |num|
          appeal = create(:appeal,
                          :hearing_docket,
                          :at_judge_review,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
          link_with_single_remand_request_issues(appeal, num)
        end
      Timecop.return
    end

    #Direct Review
    def create_ama_appeals_ready_to_dispatch_remanded_dr(attorney)
      Timecop.travel(65.days.ago)
        (0..17).each do |num|
          appeal = create(:appeal,
                          :direct_review_docket,
                          :at_judge_review,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
          link_with_single_remand_request_issues(appeal, num)
        end
      Timecop.return
    end


    #Appeals Ready for Decision with Multiple(2) Remands
    #Evidence Submission
    def create_ama_appeals_ready_to_dispatch_remanded_multiple_es(attorney)
      Timecop.travel(40.days.ago)
        (0..17).each do |num|
          appeal = create(:appeal,
                          :evidence_submission_docket,
                          :at_judge_review,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 4,
                          veteran: create_veteran)
          link_with_multiple_remand_request_issues(appeal, num)
        end
      Timecop.return
    end

    #Hearing
    def create_ama_appeals_ready_to_dispatch_remanded_multiple_hr(attorney)
      Timecop.travel(100.days.ago)
        (0..17).each do |num|
          appeal = create(:appeal,
                          :hearing_docket,
                          :at_judge_review,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 4,
                          veteran: create_veteran)
          link_with_multiple_remand_request_issues(appeal, num)
        end
      Timecop.return
    end

    #Direct Review
    def create_ama_appeals_ready_to_dispatch_remanded_multiple_dr(attorney)
      Timecop.travel(70.days.ago)
        (0..17).each do |num|
          appeal = create(:appeal,
                          :direct_review_docket,
                          :at_judge_review,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 4,
                          veteran: create_veteran)
          link_with_multiple_remand_request_issues(appeal, num)
        end
      Timecop.return
    end
  end
end
