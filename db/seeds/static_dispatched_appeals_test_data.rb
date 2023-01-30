# frozen_string_literal: true

# This seed is intended to create specific test cases without changing the ID values for test data. Adding test
# cases to other seed files changes the order in which data is created and therefore the ID values of data,
# which can make regression testing difficult or change the ID values of known cases used in manual testing.

module Seeds
  class StaticDispatchedAppealsTestData < Base
    def initialize
      initial_id_values(600_000_000, 900_000_000)
    end

    def seed!
      cases_for_dispatched_appeals_to_add_cavc_remand
    end

    private

    def cases_for_dispatched_appeals_to_add_cavc_remand
      10.times do
        nonpriority_case_with_dispatch_task_to_add_cavc_remand
      end
    end

    def nonpriority_case_with_dispatch_task_to_add_cavc_remand
      Timecop.travel(62.days.ago)
      appeal = create(:appeal,
                      :with_decision_issue,
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

      appeal.tasks.of_type(:AttorneyTask).first.completed!
      root_task = appeal.tasks.find_by(type: "RootTask")
      BvaDispatchTask.create_from_root_task(root_task)
      appeal.tasks.each { |task| task.update(status: 'completed') }
      Timecop.return
    end
  end
end
