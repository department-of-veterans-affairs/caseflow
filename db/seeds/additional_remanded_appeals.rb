# frozen_string_literal: true

module Seeds
  class AdditionalRemandedAppeals < Base
    def initialize
      initial_id_values
    end

    def seed!
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

    def judge
      @judge ||= User.find_by_css_id("BVAAABSHIRE")
    end

    def attorney
      @attorney ||= User.find_by_css_id("BVASCASPER1")
    end

    def create_allowed_request_issue_1(appeal)
      nca = BusinessLine.find_by(name: "National Cemetery Administration")
      description = "Service connection for pain disorder is granted with an evaluation of 25\% effective August 1 2020"
      notes = "Pain disorder with 25\% evaluation per examination"

      1.times do |index|
        board_grant_task = create(:board_grant_effectuation_task,
                                  status: "assigned",
                                  assigned_to: nca,
                                  appeal: appeal)

        request_issues = create_list(:request_issue, 1,
                                     :nonrating,
                                     contested_issue_description: "#{index} #{description}",
                                     notes: "#{index} #{notes}",
                                     benefit_type: "nca",
                                     decision_review: board_grant_task.appeal)

        request_issues.each do |request_issue|
          # create matching decision issue
          create(
            :decision_issue,
            :nonrating,
            # :ama_remand_reason,
            disposition: "allowed",
            decision_review: board_grant_task.appeal,
            request_issues: [request_issue],
            rating_promulgation_date: 2.months.ago,
            benefit_type: "nca"
          )
        end
      end
    end

    def create_allowed_request_issue_2(appeal)
      education = BusinessLine.find_by(name: "Education")
      description = "Service connection for pain disorder is granted with an evaluation of 50\% effective August 2 2021"
      notes = "Pain disorder with 50\% evaluation per examination"

      1.times do |index|
        board_grant_task = create(:board_grant_effectuation_task,
                                  status: "assigned",
                                  assigned_to: education,
                                  appeal: appeal)

        request_issues = create_list(:request_issue, 1,
                                     :nonrating,
                                     contested_issue_description: "#{index} #{description}",
                                     notes: "#{index} #{notes}",
                                     benefit_type: "education",
                                     decision_review: board_grant_task.appeal)

        request_issues.each do |request_issue|
          # create matching decision issue
          create(
            :decision_issue,
            :nonrating,
            # :ama_remand_reason,
            disposition: "allowed",
            decision_review: board_grant_task.appeal,
            request_issues: [request_issue],
            rating_promulgation_date: 1.month.ago,
            benefit_type: "education"
          )
        end
      end
    end

    def create_remanded_request_issue_1(appeal)
      compensation = BusinessLine.find_by(name: "Compensation")
      description = "Service connection for pain disorder is granted with an evaluation of 75\% effective February 3 2021"
      notes = "Pain disorder with 75\% evaluation per examination"

      1.times do |index|
        board_grant_task = create(:board_grant_effectuation_task,
                                  status: "assigned",
                                  assigned_to: compensation,
                                  appeal: appeal)

        request_issues = create_list(:request_issue, 1,
                                     :nonrating,
                                     contested_issue_description: "#{index} #{description}",
                                     notes: "#{index} #{notes}",
                                     benefit_type: "compensation",
                                     decision_review: board_grant_task.appeal)

        request_issues.each do |request_issue|
          # create matching decision issue
          create(
            :decision_issue,
            :nonrating,
            # :ama_remand_reason, no trait is found, create a trait in decision_issues factory and use
            disposition: "remanded",
            decision_review: board_grant_task.appeal,
            request_issues: [request_issue],
            rating_promulgation_date: 1.month.ago,
            benefit_type: "compensation"
          )
        end
      end
    end

    def create_remanded_request_issue_2(appeal)
      compensation = BusinessLine.find_by(name: "Compensation")
      description = "Service connection for pain disorder is granted with an evaluation of 100\% effective February 4 2021"
      notes = "Pain disorder with 100\% evaluation per examination"

      1.times do |index|
        board_grant_task = create(:board_grant_effectuation_task,
                                  status: "assigned",
                                  assigned_to: compensation,
                                  appeal: appeal)

        request_issues = create_list(:request_issue, 1,
                                     :nonrating,
                                     contested_issue_description: "#{index} #{description}",
                                     notes: "#{index} #{notes}",
                                     benefit_type: "compensation",
                                     decision_review: board_grant_task.appeal)

        request_issues.each do |request_issue|
          # create matching decision issue
          create(
            :decision_issue,
            :nonrating,
            # :ama_remand_reason,
            disposition: "remanded",
            decision_review: board_grant_task.appeal,
            request_issues: [request_issue],
            rating_promulgation_date: 1.month.ago,
            benefit_type: "compensation"
          )
        end
      end
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
        "advisory_medical_opinion",
        "due_process_deficiency",
#New Remand Reasons not implemented yet - need actual IDs, not just text output
=begin
        "No medical examination",
        "Inadequate medical examination",
        "No medical opinion",
        "Inadequate medical opinion",
        "Advisory medical opinion",
        "Inextricably intertwined",
        "Error satisfying regulatory or statutory duty",
        "Other",
=end
      ]
    end

    #Appeals Ready for Decision - Attorney Step
    #Evidence Submission
    def create_ama_appeals_decision_ready_es
      Timecop.travel(30.days.ago)
        15.times do
          appeal = create(:appeal,
                          :evidence_submission_docket,
                          :at_attorney_drafting,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
        end
      Timecop.return
    end

    #Hearing
    def create_ama_appeals_decision_ready_hr
      Timecop.travel(90.days.ago)
        15.times do
          appeal = create(:appeal,
                          :hearing_docket,
                          :with_request_issues,
                          :at_attorney_drafting,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
        end
      Timecop.return
    end

    #Direct Review
    def create_ama_appeals_decision_ready_dr
      Timecop.travel(60.days.ago)
        15.times do
          appeal = create(:appeal,
                          :direct_review_docket,
                          :with_request_issues,
                          :at_attorney_drafting,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
        end
      Timecop.return
    end

    def link_request_issues(appeal)
      create_allowed_request_issue_1(appeal)
      create_allowed_request_issue_2(appeal)
      create_remanded_request_issue_1(appeal)
    end

    #Appeals Ready for Decision with 1 Remand
    #Evidence Submission
    def create_ama_appeals_ready_to_dispatch_remanded_es
      Timecop.travel(30.days.ago)
        (1..12).each do |i|
          appeal = create(:appeal,
                          :evidence_submission_docket,
                          :with_decision_issue,
                          :at_judge_review,
                          # code: decision_reason_remand_list.at(i-1),
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
          link_request_issues(appeal)
        end
      Timecop.return
    end

    #Hearing
    def create_ama_appeals_ready_to_dispatch_remanded_hr
      Timecop.travel(90.days.ago)
        (1..12).each do |i|
          appeal = create(:appeal,
                          :hearing_docket,
                          :with_decision_issue,
                          :at_judge_review,
                          # code: decision_reason_remand_list.at(i-1),
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
          link_request_issues(appeal)
        end
      Timecop.return
    end

    #Direct Review
    def create_ama_appeals_ready_to_dispatch_remanded_dr
      Timecop.travel(60.days.ago)
        (1..12).each do |i|
          appeal = create(:appeal,
                          :direct_review_docket,
                          :with_decision_issue,
                          :at_judge_review,
                          # code: decision_reason_remand_list.at(i-1), code is not related to appeal you need to create ama_remand_reason trait and add code to it and link it decision_issues
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 3,
                          veteran: create_veteran)
          link_request_issues(appeal)
        end
      Timecop.return
    end


    #Appeals Ready for Decision with Multiple(2) Remands
    #Evidence Submission
    def create_ama_appeals_ready_to_dispatch_remanded_multiple_es
      Timecop.travel(30.days.ago)
        (1..12).each do |i|
          appeal = create(:appeal,
                          :evidence_submission_docket,
                          :with_decision_issue,
                          :at_judge_review,
                          # code: decision_reason_remand_list.at(i-1),
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 4,
                          veteran: create_veteran)
          link_request_issues(appeal)
          create_remanded_request_issue_2(appeal)
        end
      Timecop.return
    end

    #Hearing
    def create_ama_appeals_ready_to_dispatch_remanded_multiple_hr
      Timecop.travel(90.days.ago)
        (1..12).each do |i|
          appeal = create(:appeal,
                          :hearing_docket,
                          :with_decision_issue,
                          :at_judge_review,
                          # code: decision_reason_remand_list.at(i-1),
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 4,
                          veteran: create_veteran)
          link_request_issues(appeal)
          create_remanded_request_issue_2(appeal)
        end
      Timecop.return
    end

    #Direct Review
    def create_ama_appeals_ready_to_dispatch_remanded_multiple_dr
      Timecop.travel(60.days.ago)
        (1..12).each do |i|
          appeal = create(:appeal,
                          :direct_review_docket,
                          :with_decision_issue,
                          :at_judge_review,
                          # code: decision_reason_remand_list.at(i-1),
                          associated_judge: judge,
                          associated_attorney: attorney,
                          issue_count: 4,
                          veteran: create_veteran)
          link_request_issues(appeal)
          create_remanded_request_issue_2(appeal)
        end
      Timecop.return
    end
  end
end

#Building each appeal individually instead (Lengthy, repetitive.)
=begin
    create_ama_appeals_ready_to_dispatch_remanded_es
      Timecop.travel(30.days.ago)
        appeal1 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "no_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal2 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "incorrect_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal3 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "legally_inadequate_notice",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal4 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "va_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal5 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "private_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal6 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_personnel_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal7 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_treatment_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal8 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "other_government_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal9 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_examinations",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal10 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_opinions",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal11 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "advisory_medical_opinion",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal12 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "due_process_deficiency",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

      Timecop.return
    end

    create_ama_appeals_ready_to_dispatch_remanded_hr
      Timecop.travel(90.days.ago)
        appeal1 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "no_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal2 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "incorrect_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal3 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "legally_inadequate_notice",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal4 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "va_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal5 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "private_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal6 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_personnel_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal7 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_treatment_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal8 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "other_government_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal9 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_examinations",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal10 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_opinions",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal11 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "advisory_medical_opinion",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal12 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "due_process_deficiency",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

      Timecop.return

      end

    create_ama_appeals_ready_to_dispatch_remanded_dr
      Timecop.travel(60.days.ago)
        appeal1 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "no_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal2 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "incorrect_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal3 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "legally_inadequate_notice",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal4 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "va_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal5 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "private_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal6 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_personnel_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal7 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_treatment_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal8 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "other_government_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal9 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_examinations",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal10 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_opinions",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal11 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "advisory_medical_opinion",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal12 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "due_process_deficiency",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

      Timecop.return
    end

    create_ama_appeals_ready_to_dispatch_remanded_multiple_es
      Timecop.travel(30.days.ago)
        appeal1 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "no_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal2 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "incorrect_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal3 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "legally_inadequate_notice",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal4 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "va_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal5 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "private_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal6 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_personnel_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal7 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_treatment_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal8 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "other_government_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal9 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_examinations",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal10 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_opinions",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal11 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "advisory_medical_opinion",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal12 = create(:appeal,
          :evidence_submission_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "due_process_deficiency",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

      Timecop.return
    end

    create_ama_appeals_ready_to_dispatch_remanded_multiple_hr
      Timecop.travel(90.days.ago)
        appeal1 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "no_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal2 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "incorrect_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal3 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "legally_inadequate_notice",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal4 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "va_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal5 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "private_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal6 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_personnel_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal7 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_treatment_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal8 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "other_government_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal9 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_examinations",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal10 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_opinions",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal11 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "advisory_medical_opinion",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal12 = create(:appeal,
          :hearing_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "due_process_deficiency",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

      Timecop.return

      end

    create_ama_appeals_ready_to_dispatch_remanded_multiple_dr
      Timecop.travel(60.days.ago)
        appeal1 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "no_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal2 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "incorrect_notice_sent",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal3 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "legally_inadequate_notice",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal4 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "va_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal5 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "private_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal6 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_personnel_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal7 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "service_treatment_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal8 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "other_government_records",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal9 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_examinations",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal10 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "medical_opinions",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal11 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "advisory_medical_opinion",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

        appeal12 = create(:appeal,
          :direct_review_docket,
          :with_request_issues,
          :remand_reasons
          :at_judge_review,
          :ama_remand_reason,
          code: "due_process_deficiency",
          associated_judge: User.find_by_css_id("BVAAABSHIRE"),
          associated_attorney: User.find_by_css_id("BVASCASPER1")
          issue_count: 3,
          veteran: create_veteran)

      Timecop.return
    end
=end
