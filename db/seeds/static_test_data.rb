# frozen_string_literal: true

# This seed is intended to create specific test cases without changing the ID values for test data. Adding test
# cases to other seed files changes the order in which data is created and therefore the ID values of data,
# which can make regression testing difficult or change the ID values of known cases used in manual testing.

module Seeds
  class StaticTestCaseData < Base
    def initialize
      initial_id_values
    end

    def seed!
      cases_for_timely_calculations_on_das
    end

    private

    def initial_id_values
      @file_number ||= 400_000_000
      @participant_id ||= 800_000_000
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

    def cases_for_timely_calculations_on_das
      2.times do
        priority_case_with_only_attorney_task
        priority_case_with_attorney_task_children
        priority_case_with_attorney_rewrite_task
        priority_case_with_long_task_tree
        nonpriority_case_with_only_attorney_task
        nonpriority_case_with_attorney_task_children
        nonpriority_case_with_attorney_rewrite_task
        nonpriority_case_with_long_task_tree
        priority_case_with_only_attorney_task(37)
        priority_case_with_attorney_task_children(32)
        priority_case_with_attorney_rewrite_task(37)
        cavc_priority_case_with_only_attorney_task
        cavc_priority_case_with_attorney_task_children
        cavc_priority_case_with_attorney_rewrite_task
        priority_case_with_only_attorney_task(0)
      end
    end

    def priority_case_with_only_attorney_task(time_travel_days = 20)
      Timecop.travel(time_travel_days.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      :advanced_on_docket_due_to_age,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def priority_case_with_attorney_task_children(time_travel_days = 15)
      Timecop.travel(time_travel_days.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      :advanced_on_docket_due_to_age,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      create(:colocated_task,
             :translation,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:privacy_act_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:foia_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      appeal.tasks.of_type(:TranslationTask).first.completed!
      appeal.tasks.of_type(:PrivacyActTask).first.completed!
      appeal.tasks.of_type(:FoiaTask).first.completed!
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def priority_case_with_attorney_rewrite_task(time_travel_days = 20)
      Timecop.travel(time_travel_days.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_judge_review,
                      :advanced_on_docket_due_to_age,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      judge_team = JudgeTeam.find_by(name: "BVAGSPORER")
      rewrite_task = create(:ama_attorney_rewrite_task,
                            parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
                            assigned_by: judge_team.users.first,
                            assigned_to: judge_team.users.last,
                            assigned_at: Time.zone.now)
      Timecop.return
      rewrite_task.completed!
    end

    def cavc_priority_case_with_only_attorney_task
      Timecop.travel(35.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      :type_cavc_remand,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def cavc_priority_case_with_attorney_task_children
      Timecop.travel(32.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      :type_cavc_remand,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      create(:colocated_task,
             :translation,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:privacy_act_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:foia_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      appeal.tasks.of_type(:TranslationTask).first.completed!
      appeal.tasks.of_type(:PrivacyActTask).first.completed!
      appeal.tasks.of_type(:FoiaTask).first.completed!
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def cavc_priority_case_with_attorney_rewrite_task
      Timecop.travel(35.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_judge_review,
                      :type_cavc_remand,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      judge_team = JudgeTeam.find_by(name: "BVAGSPORER")
      rewrite_task = create(:ama_attorney_rewrite_task,
                            parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
                            assigned_by: judge_team.users.first,
                            assigned_to: judge_team.users.last,
                            assigned_at: Time.zone.now)
      Timecop.return
      rewrite_task.completed!
    end

    def nonpriority_case_with_only_attorney_task
      Timecop.travel(65.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def nonpriority_case_with_attorney_task_children
      Timecop.travel(62.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      create(:colocated_task,
             :translation,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:privacy_act_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:foia_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      appeal.tasks.of_type(:TranslationTask).first.completed!
      appeal.tasks.of_type(:PrivacyActTask).first.completed!
      appeal.tasks.of_type(:FoiaTask).first.completed!
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def nonpriority_case_with_attorney_rewrite_task
      Timecop.travel(65.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_judge_review,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      judge_team = JudgeTeam.find_by(name: "BVAGSPORER")
      rewrite_task = create(:ama_attorney_rewrite_task,
                            parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
                            assigned_by: judge_team.users.first,
                            assigned_to: judge_team.users.last,
                            assigned_at: Time.zone.now)
      Timecop.return
      rewrite_task.completed!
    end

    def priority_case_with_long_task_tree
      judge_team = JudgeTeam.find_by(name: "BVAEBECKER")
      Timecop.travel(15.months.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      :advanced_on_docket_due_to_age,
                      associated_judge: User.find_by_css_id("BVAEBECKER"),
                      associated_attorney: judge_team.users.last,
                      issue_count: 1,
                      veteran: create_veteran)
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :foia,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(5.months.from_now)
      appeal.tasks.of_type(:FoiaTask).first.completed!
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :ihp,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(3.months.from_now)
      appeal.tasks.of_type(:IhpColocatedTask).first.completed!
      Timecop.travel(5.days.from_now)
      appeal.tasks.of_type(:AttorneyTask).first.completed!
       # Create AttorneyRewriteTask, this indicates appeal was sent back to the judge
      # and has been returned to attorney
      Timecop.travel(1.week.from_now)
      create(:ama_attorney_rewrite_task,
             parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
             assigned_by: judge_team.users.first,
             assigned_to: judge_team.users.last,
             assigned_at: Time.zone.now)
      # Create Other task under first AttorneyRewriteTask
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :other,
             parent: appeal.tasks.of_type(:AttorneyRewriteTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(2.weeks.from_now)
      appeal.tasks.of_type(:OtherColocatedTask).first.completed!
      Timecop.travel(1.weeks.from_now)
      appeal.tasks.of_type(:AttorneyRewriteTask).first.completed!
      # Create Second AttorneyRewriteTask
      Timecop.travel(1.week.from_now)
      create(:ama_attorney_rewrite_task,
             parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
             assigned_by: judge_team.users.first,
             assigned_to: judge_team.users.last,
             assigned_at: Time.zone.now)
      Timecop.travel(2.weeks.from_now)
      appeal.tasks.of_type(:AttorneyRewriteTask).second.completed!
      Timecop.return
    end

    def nonpriority_case_with_long_task_tree
      judge_team = JudgeTeam.find_by(name: "BVAEBECKER")
      Timecop.travel(15.months.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      associated_judge: User.find_by_css_id("BVAEBECKER"),
                      associated_attorney: judge_team.users.last,
                      issue_count: 1,
                      veteran: create_veteran)
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :foia,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(5.months.from_now)
      appeal.tasks.of_type(:FoiaTask).first.completed!
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :ihp,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(3.months.from_now)
      appeal.tasks.of_type(:IhpColocatedTask).first.completed!
      Timecop.travel(5.days.from_now)
      appeal.tasks.of_type(:AttorneyTask).first.completed!
       # Create AttorneyRewriteTask, this indicates appeal was sent back to the judge
      # and has been returned to attorney
      Timecop.travel(1.week.from_now)
      create(:ama_attorney_rewrite_task,
             parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
             assigned_by: judge_team.users.first,
             assigned_to: judge_team.users.last,
             assigned_at: Time.zone.now)
      # Create Other task under first AttorneyRewriteTask
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :other,
             parent: appeal.tasks.of_type(:AttorneyRewriteTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(2.weeks.from_now)
      appeal.tasks.of_type(:OtherColocatedTask).first.completed!
      Timecop.travel(1.weeks.from_now)
      appeal.tasks.of_type(:AttorneyRewriteTask).first.completed!
      # Create Second AttorneyRewriteTask
      Timecop.travel(1.week.from_now)
      create(:ama_attorney_rewrite_task,
             parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
             assigned_by: judge_team.users.first,
             assigned_to: judge_team.users.last,
             assigned_at: Time.zone.now)
      Timecop.travel(2.weeks.from_now)
      appeal.tasks.of_type(:AttorneyRewriteTask).second.completed!
      Timecop.return
    end
  end
end
