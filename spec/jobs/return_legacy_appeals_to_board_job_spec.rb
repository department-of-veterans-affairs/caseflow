# frozen_string_literal: true

describe ReturnLegacyAppealsToBoardJob, :all_dbs do
  describe "#perform" do
    let(:job) { described_class.new }
    let(:returned_appeal_job) { instance_double("ReturnedAppealJob", id: 1) }
    let(:appeals) { [{ "bfkey" => "1", "priority" => 1 }, { "bfkey" => "2", "priority" => 0 }] }
    let(:moved_appeals) { [{ "bfkey" => "1", "priority" => 1 }] }

    before do
      allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(2)

      allow(job).to receive(:create_returned_appeal_job).and_return(returned_appeal_job)
      allow(returned_appeal_job).to receive(:update!)
      allow(job).to receive(:eligible_and_moved_appeals).and_return([appeals, moved_appeals])
      allow(job).to receive(:filter_appeals).and_return({})
      allow(job).to receive(:send_job_slack_report)
      allow(job).to receive(:complete_returned_appeal_job)
      allow(job).to receive(:metrics_service_report_runtime)
    end

    context "when the job completes successfully" do
      it "creates a ReturnedAppealJob instance, processes appeals, and sends a report" do
        allow(job).to receive(:slack_report).and_return(["Job completed successfully"])

        job.perform

        expect(job).to have_received(:create_returned_appeal_job).once
        expect(job).to have_received(:eligible_and_moved_appeals).once
        expect(job).to have_received(:complete_returned_appeal_job)
          .with(returned_appeal_job, "Job completed successfully", moved_appeals).once
        expect(job).to have_received(:send_job_slack_report).with(["Job completed successfully"]).once
        expect(job).to have_received(:metrics_service_report_runtime)
          .with(metric_group_name: "return_legacy_appeals_to_board_job").once
      end
    end

    context "when no appeals are moved" do
      before do
        allow(job).to receive(:eligible_and_moved_appeals).and_return([appeals, nil])
        allow(job).to receive(:slack_report).and_return(["Job Ran Successfully, No Records Moved"])
      end

      it "sends a no records moved Slack report" do
        job.perform

        expect(job).to have_received(:send_job_slack_report).with(["Job Ran Successfully, No Records Moved"]).once
        expect(job).to have_received(:metrics_service_report_runtime).once
      end
    end

    context "when an error occurs" do
      let(:error_message) { "Unexpected error" }
      let(:slack_service_instance) { instance_double(SlackService) }

      before do
        allow(job).to receive(:eligible_and_moved_appeals).and_raise(StandardError, error_message)
        allow(job).to receive(:log_error)
        allow(returned_appeal_job).to receive(:update!)
        allow(SlackService).to receive(:new).and_return(slack_service_instance)
        allow(slack_service_instance).to receive(:send_notification)
      end

      it "handles the error, logs it, and sends a Slack notification" do
        job.perform

        expect(job).to have_received(:log_error).with(instance_of(StandardError))
        expect(returned_appeal_job).to have_received(:update!)
          .with(hash_including(errored_at: kind_of(Time),
                               stats: "{\"message\":\"Job failed with error: #{error_message}\"}")).once
        expect(slack_service_instance).to have_received(:send_notification).with(
          a_string_matching(/<!here>\n \[ERROR\]/), job.class.name
        ).once
        expect(job).to have_received(:metrics_service_report_runtime).once
      end
    end
  end
end


functions

Given that 2 non_ssc_avljs exist
When this non_ssc_avljs()
I expect an array containing both non_ssc_avljs are returned

Given that 1 non ssc avljs and 1 each of ssc avlj, regular vlj, inactive non ssc avlj, ...
When this non_ssc_avljs()
I expect an array containing only the non ssc avlj to be returned

Given that no ssc avljs exist
When this non_ssc_avljs()
I expect an empty array to be returned

-------

Given that
  - 4 appeals exist (2 priority and 2 non-priority and
  - a subset of 2 of those appeals (1 priority and 1 non-priority) are assigned to priority_appeals_moved and non_priority_appeals_moved respectively
When this calculate_remaining_appeals(appeals,priority_appeals_moved,non_priority_appeals_moved)
I expect an array of arrays be be returned with:
- the first subarray to contain the priority appeal that was NOT moved and
- the second subarray to contain the non-priority appeal that was NOT moved

Given that
  - 2 priority appeals exist and
  - no non-priority_appeals exist
  - 1 of those priority_appealsis assgined to priority_appeals_moved and
  - non_priority_appeals_moved is an empty array
When this calculate_remaining_appeals(appeals,priority_appeals_moved,non_priority_appeals_moved)
I expect an array of arrays be be returned with:
- the first subarray to contain the priority appeal that was NOT moved and
- the second subarray to contain an empty array

Given that
  - no priority appeals exist and
  - 2 non-priority_appeals exist
  - priority_appeals_moved is an empty array and
  - 1 of those non-priority_appeals is assigned to non_priority_appeals_moved
When this calculate_remaining_appeals(appeals,priority_appeals_moved,non_priority_appeals_moved)
I expect an array of arrays be be returned with:
- the first subarray to contain an empty array and
- the second subarray to contain the non-priority appeal that was NOT moved

Given that
  - 4 appeals exist (2 priority and 2 non-priority and
  - a subset of all 4 of those appeals (2 priority and 2 non-priority) are assigned to priority_appeals_moved and non_priority_appeals_moved respectively
When this calculate_remaining_appeals(appeals,priority_appeals_moved,non_priority_appeals_moved)
I expect an array of arrays be be returned with:
- the first subarray to contain an empty array and
- the second subarray to contain an empty array

Given that
  - appeals = []
  - assigned to priority_appeals_moved = [] and
  - non_priority_appeals_moved respectively = []
When this calculate_remaining_appeals(appeals,priority_appeals_moved,non_priority_appeals_moved)
I expect an error to be raised stating that appeals is an empty array


------

Given that
  - 4 appeals exist (2 priority and 2 non-priority)
  - and a subset of 2 of those appeals (1 priority and 1 non-priority) are assigned to moved_appeals: [[priority_appeals_moved],[non_priority_appeals_moved]]
When this filter_appeals(appeals, moved_appeals)
I expect the returned message to reflect the correct counts of total and moved appeals

Given that
  - 4 appeals exist (2 priority and 2 non-priority)
  - and a subset of all 4 of those appeals (2 priority and 2 non-priority) are assigned to moved_appeals: [[priority_appeals_moved],[non_priority_appeals_moved]]
When this filter_appeals(appeals, moved_appeals)
I expect the returned message to reflect the correct counts of total and moved appeals
    - with no remaining appeals left
    - all appeals moved

Given that
  - 4 appeals exist (2 priority and 2 non-priority)
  - and moved_appeals = [[],[]] (two empty arrays within an array)
When this filter_appeals(appeals, moved_appeals)
I expect the returned message to reflect the correct counts of total and moved appeals
    - with all appeals left
    - no appeals moved

Given that
  - appeals = 4 appeals [2 priority and 2 non-priority] and
  - 1 extra priorty appeal exists that is not included in the appeals object
  - priority_appeals_moved = [both priority appeals + the extra priority appeal] and
  - non_priority_appeals_moved = [both non-priority appeals] and
  - moved_appeals = [[priority_appeals_moved],[non_priority_appeals_moved]]
When this filter_appeals(appeals, moved_appeals)
I expect an error to be raised that states there are too many priority appeals in priority appeals moved

Given that
  - appeals = 4 appeals [2 priority and 2 non-priority] and
  - 1 extra non-priorty appeal exists that is not included in the appeals object
  - priority_appeals_moved = [both priority appealsl] and
  - non_priority_appeals_moved = [both non-priority appeals  + the extra non-priority appea] and
  - moved_appeals = [[priority_appeals_moved],[non_priority_appeals_moved]]
When this filter_appeals(appeals, moved_appeals)
I expect an error to be raised that states there are too many non-priority appeals in non-priority appeals moved

-------

Given that ??
When this create_returned_appeal_job()
I expect a ReturnedAppealJob is returned with the right started_at and stats variables

-------

Given that
  - @filtered_appeals is set up with the proper attributes
  - slack_report will return the array of messages with @filtered_appeals variables
When this send_job_slack_report()
I expect slack_service.send_notification recieves the correct message with the same variables in @filtered_appeals

Given that
  - @filtered_appeals is set up with the proper attributes
  - slack_report will return an empty array
When this send_job_slack_report()
I expect an error to be raised stating that the slack_report is empty

----

Given that
  - returned_appeal_job is set
  - 4 moved_appeals is a set of objects each with a uniq "bfkey" attribute
When this complete_returned_appeal_job(returned_appeal_job, "Job completed successfully", moved_appeals)
I expect returned_appeal_job is updated with
  - completed_at set to the correct time
  - stats set to "Job completed successfully"
  - returned_appeals contains the 4 bfkeys matching those of the moved_appeals

Given that
  - returned_appeal_job is set
  - 4 moved_appeals is a set of objects each with a "bfkey" attribute
    - 2 with uniq "bfkeys"
    - 2 sharing the same "bfkey"
When this complete_returned_appeal_job(returned_appeal_job, "Job completed successfully", moved_appeals)
I expect returned_appeal_job is updated with
  - completed_at set to the correct time
  - stats set to "Job completed successfully"
  - returned_appeals contains 3 uniq bfkeys matching those of the moved_appeals

Given that
  - returned_appeal_job is set
  - moved_appeals is an empty array
When this complete_returned_appeal_job(returned_appeal_job, "Job completed successfully", moved_appeals)
I expect an error to be raised stating that there were no moved appeals

Given that
  - returned_appeal_job is nil
  - 4 moved_appeals is a set of objects each with a uniq "bfkey" attribute
When this complete_returned_appeal_job(returned_appeal_job, "Job completed successfully", moved_appeals)
I expect an error to be raised stating that the returned_appeal_job did not exist

------

Given that
  - 4 appeals exist (2 priority and 2 non-priority)
  - LegacyDocket.new.appeals_tied_to_non_ssc_avljs() returns an array of all the appeals
  - move_qualifying_appeals() returns an array of 1 of the priority appeals and 1 of the non-priority appeals
When this eligible_and_moved_appeal
I expect it to return [[all 4 appeals],[the appeals returned by move_qualifying_appeals()]]

Given that
  - LegacyDocket.new.appeals_tied_to_non_ssc_avljs() returns an empty array
  - move_qualifying_appeals() returns an empty array
When this eligible_and_moved_appeal
I expect it to return [[],[]]

------

Given that
  - VACOLS::Case.batch_update_vacols_location is set up correctly to run (VacolsLocationBatchUpdater too?) or mocked?
  - 2 VACOLS::Staff (or object with the sattyid attribute) exist that each have a unique sattyid
  - non_ssc_avljs() returns an array of both of those Staff (or objects)
  - @nonsscavlj_number_of_appeals_limit = 2
  - @nonsscavlj_number_of_appeals_to_move = 1
  - 8 appeals exist:
    - 4 non-priority with "bfd19" set to 10 days ago
      - 2 tied to the first staff and 2 tied to the second staff
    - 4 priority with "bfd19" set to 2 days ago
      - 2 tied to the first staff and 2 tied to the second staff
When this move_qualifying_appeals(appeals)
I expect
  - VACOLS::Case.batch_update_vacols_location runs
  - all 4 priority appeals BFCURLOC is updated to '63'
  - all 4 priority appeals BFDLOOUT is updated
  - it returns an array of the 4 priority appeals


Given that
  - VACOLS::Case.batch_update_vacols_location is set up correctly to run (VacolsLocationBatchUpdater too?) or mocked?
  - 2 VACOLS::Staff (or object with the sattyid attribute) exist that each have a unique sattyid
  - non_ssc_avljs() returns an array of both of those Staff (or objects)
  - @nonsscavlj_number_of_appeals_limit = 1
  - @nonsscavlj_number_of_appeals_to_move = 0
  - 8 appeals exist:
    - 4 non-priority with "bfd19" set to 10 days ago
      - 2 tied to the first staff and 2 tied to the second staff
    - 4 priority with "bfd19" set to 2 days ago
      - 2 tied to the first staff and 2 tied to the second staff
When this move_qualifying_appeals(appeals)
I expect
  - VACOLS::Case.batch_update_vacols_location runs
  - all 2 priority appeals BFCURLOC is updated to '63'
  - all 2 priority appeals BFDLOOUT is updated
  - it returns an array of the 2 priority appeals
    - 1 from each Staff

Given that
  - VACOLS::Case.batch_update_vacols_location is set up correctly to run (VacolsLocationBatchUpdater too?) or mocked?
  - 2 VACOLS::Staff (or object with the sattyid attribute) exist that each have a unique sattyid
  - non_ssc_avljs() returns an array of both of those Staff (or objects)
  - @nonsscavlj_number_of_appeals_limit = 10
  - @nonsscavlj_number_of_appeals_to_move = 9
  - 8 appeals exist:
    - 4 non-priority with "bfd19" set to 10 days ago
      - 2 tied to the first staff and 2 tied to the second staff
    - 4 priority with "bfd19" set to 2 days ago
      - 2 tied to the first staff and 2 tied to the second staff
When this move_qualifying_appeals(appeals)
I expect
  - VACOLS::Case.batch_update_vacols_location runs
  - all 8 appeals BFCURLOC is updated to '63'
  - all 8 appeals BFDLOOUT is updated
  - it returns an array of the 8 appeals

Given that
  - VACOLS::Case.batch_update_vacols_location is set up correctly to run (VacolsLocationBatchUpdater too?) or mocked?
  - non_ssc_avljs() returns an empty array
  - @nonsscavlj_number_of_appeals_limit = 1
  - @nonsscavlj_number_of_appeals_to_move = 0
  - 8 appeals exist:
    - 4 non-priority with "bfd19" set to 10 days ago
      - 2 tied to the first staff and 2 tied to the second staff
    - 4 priority with "bfd19" set to 2 days ago
      - 2 tied to the first staff and 2 tied to the second staff
When this move_qualifying_appeals(appeals)
I expect
  - VACOLS::Case.batch_update_vacols_location does not run
  - it returns an empty array

Given that
  - VACOLS::Case.batch_update_vacols_location is set up correctly to run (VacolsLocationBatchUpdater too?) or mocked?
  - 2 VACOLS::Staff (or object with the sattyid attribute) exist that each have a unique sattyid
  - non_ssc_avljs() returns an array of both of those Staff (or objects)
  - @nonsscavlj_number_of_appeals_limit = 1
  - @nonsscavlj_number_of_appeals_to_move = 0
  - no appeals exist
When this move_qualifying_appeals(appeals)
I expect
  - VACOLS::Case.batch_update_vacols_location does not run
  - it returns an empty array

  Given that
  - VACOLS::Case.batch_update_vacols_location is set up correctly to run (VacolsLocationBatchUpdater too?) or mocked?
  - 2 VACOLS::Staff (or object with the sattyid attribute) exist that each have a unique sattyid
  - non_ssc_avljs() returns an array of both of those Staff (or objects)
  - @nonsscavlj_number_of_appeals_limit = 0
  - @nonsscavlj_number_of_appeals_to_move = -1
  - 8 appeals exist:
    - 4 non-priority with "bfd19" set to 10 days ago
      - 2 tied to the first staff and 2 tied to the second staff
    - 4 priority with "bfd19" set to 2 days ago
      - 2 tied to the first staff and 2 tied to the second staff
When this move_qualifying_appeals(appeals)
I expect
  - VACOLS::Case.batch_update_vacols_location does not run
  - it returns an empty array

------
Given that
  - appeal_1 = {priority: 0, bfd19: 10.days.ago, bfkey: "1"}
  - appeal_2 = {priority: 1, bfd19: 8.days.ago, bfkey: "2"}
  - appeal_3 = {priority: 0, bfd19: 6.days.ago, bfkey: "3"}
  - appeal_4 = {priority: 1, bfd19: 4.days.ago, bfkey: "4"}
  - tied_appeals = [appeal_1, appeal_2, appeal_3, appeal_4]
When this get_tied_appeal_bfkeys(tied_appeals)
I expect it to return ["2", "4", "1", "3"]

-------
Given that
  - tied_appeals_bfkeys = ["3", "4", "5", "6"]
  - qualifying_appeals_bfkeys = ["1", "2"]
  - @nonsscavlj_number_of_appeals_limit = 2
  - @nonsscavlj_number_of_appeals_to_move = @nonsscavlj_number_of_appeals_limit - 1
When this   update_qualifying_appeals_bfkeys(tied_appeals_bfkeys, qualifying_appeals_bfkeys)?
I expect it to return  ["1", "2", "3", "4"]

Given that
  - tied_appeals_bfkeys = ["3", "4", "5", "6"]
  - qualifying_appeals_bfkeys = ["1", "2"]
  - @nonsscavlj_number_of_appeals_limit = 4
  - @nonsscavlj_number_of_appeals_to_move = @nonsscavlj_number_of_appeals_limit - 1
When this   update_qualifying_appeals_bfkeys(tied_appeals_bfkeys, qualifying_appeals_bfkeys)?
I expect it to return  ["1", "2", "3", "4", "5", "6"]

Given that
  - tied_appeals_bfkeys = ["3", "4", "5", "6"]
  - qualifying_appeals_bfkeys = ["1", "2"]
  - @nonsscavlj_number_of_appeals_limit = 10
  - @nonsscavlj_number_of_appeals_to_move = @nonsscavlj_number_of_appeals_limit - 1
When this   update_qualifying_appeals_bfkeys(tied_appeals_bfkeys, qualifying_appeals_bfkeys)?
I expect it to return  ["1", "2", "3", "4", "5", "6"]

Given that
  - tied_appeals_bfkeys = ["3", "4", "5", "6"]
  - qualifying_appeals_bfkeys = []
  - @nonsscavlj_number_of_appeals_limit = 2
  - @nonsscavlj_number_of_appeals_to_move = @nonsscavlj_number_of_appeals_limit - 1
When this   update_qualifying_appeals_bfkeys(tied_appeals_bfkeys, qualifying_appeals_bfkeys)?
I expect it to return  ["3", "4"]

Given that
  - tied_appeals_bfkeys = []
  - qualifying_appeals_bfkeys = ["1", "2"]
  - @nonsscavlj_number_of_appeals_limit = 2
  - @nonsscavlj_number_of_appeals_to_move = @nonsscavlj_number_of_appeals_limit - 1
When this   update_qualifying_appeals_bfkeys(tied_appeals_bfkeys, qualifying_appeals_bfkeys)?
I expect it to return  ["1", "2"]

Given that
  - tied_appeals_bfkeys = []
  - qualifying_appeals_bfkeys = []
  - @nonsscavlj_number_of_appeals_limit = 2
  - @nonsscavlj_number_of_appeals_to_move = @nonsscavlj_number_of_appeals_limit - 1
When this   update_qualifying_appeals_bfkeys(tied_appeals_bfkeys, qualifying_appeals_bfkeys)?
I expect it to return  []

Given that
  - tied_appeals_bfkeys = ["3", "4", "5", "6"]
  - qualifying_appeals_bfkeys = ["1", "2"]
  - @nonsscavlj_number_of_appeals_limit = -1
  - @nonsscavlj_number_of_appeals_to_move = @nonsscavlj_number_of_appeals_limit - 1
When this   update_qualifying_appeals_bfkeys(tied_appeals_bfkeys, qualifying_appeals_bfkeys)?
I expect it to return  an error stating that @nonsscavlj_number_of_appeals_limit cant be less than 0
or move this to error handling on the lever?

------

X - dont make tests
O - make test

- perform <--- O
  - create_returned_appeal_job() <--- O
  - eligible_and_moved_appeals() <--- ?
    - move_qualifying_appeals() <--- O
      - get_tied_appeal_bfkeys() <--- X?
      - update_qualifying_appeals_bfkeys() <--- X?
      - VACOLS::Case.batch_update_vacols_location <--- X
        - VacolsLocationBatchUpdater.new() <--- X
        - VacolsLocationBatchUpdater.call() <--- X
  - complete_returned_appeal_job() <--- O
    - returned_appeal_job.update!() <--- X
  - filter_appeals() <--- O
    - separate_by_priority() <--- X?
    - calculate_remaining_appeals() <--- O?
    - count_unique_bfkeys() <--- X?
    - grouped_by_avlj() <--- ?
      - VACOLS::Staff.find_by() <--- X
  - send_job_slack_report() <--- O
    - slack_service.send_notification() <--- X
    - slack_report() <--- O
      - @filtered_appeals <--- X
  -errored_returned_appeal_job() <--- O?

-fetch_moved_sattyids() not used? remove?
