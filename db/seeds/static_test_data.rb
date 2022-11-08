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
        nonpriority_case_with_only_attorney_task
        nonpriority_case_with_attorney_task_children
        nonpriority_case_with_attorney_rewrite_task
      end
    end

    def priority_case_with_only_attorney_task
      Timecop.travel(20.days.ago)
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

    def priority_case_with_attorney_task_children
      Timecop.travel(15.days.ago)
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
      appeal.tasks.of_type(:TranslationTask).first.completed!
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def priority_case_with_attorney_rewrite_task
      Timecop.travel(20.days.ago)
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
                            assigned_to: judge_team.users.last)
      Timecop.return
      rewrite_task.completed!
    end

    def nonpriority_case_with_only_attorney_task
      Timecop.travel(20.days.ago)
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
      Timecop.travel(15.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      create(:colocated_task, :translation, parent: appeal.tasks.of_type(:AttorneyTask).first)
      appeal.tasks.of_type(:TranslationTask).first.completed!
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def nonpriority_case_with_attorney_rewrite_task
      Timecop.travel(20.days.ago)
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
                            assigned_to: judge_team.users.last)
      Timecop.return
      rewrite_task.completed!
    end
  end
end
