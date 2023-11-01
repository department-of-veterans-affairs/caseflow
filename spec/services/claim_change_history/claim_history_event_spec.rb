# frozen_string_literal: true

# I hate doing this
require_relative "../../../app/services/claim_change_history/claim_history_event.rb"

describe ClaimHistoryEvent do
  let(:change_data) do
    {
      "id" => nil,
      "appeal_id" => 155,
      "appeal_type" => change_data_claim_type,
      "assigned_at" => "2023-10-19 22:47:16.222148",
      "assigned_by_id" => nil,
      "assigned_to_id" => 200_000_022_2,
      "assigned_to_type" => "Organization",
      "closed_at" => nil,
      "completed_by_id" => nil,
      "created_at" => nil,
      "placed_on_hold_at" => "2023-10-19 22:45:43.148646",
      "started_at" => "2023-10-19 22:36:44.417478",
      "decision_date" => "2023-05-31",
      "nonrating_issue_category" => "Clothing Allowance",
      "nonrating_issue_description" => "Clothing allowance no decision date",
      "decision_date_added_at" => "2023-10-19 22:47:16.233187",
      "veteran_file_number" => "000100022",
      "after_request_issue_ids" => "{4008,4006,4007}",
      "before_request_issue_ids" => "{4008,4006}",
      "edited_request_issue_ids" => "{4008}",
      "withdrawn_request_issue_ids" => "{}",
      "caseflow_decision_date" => "2023-10-19",
      "decision_text" => nil,
      "description" => "granting clothing allowance",
      "disposition" => "Granted",
      "first_name" => "Bob",
      "last_name" => "Smithboehm",
      "middle_name" => nil,
      "name_suffix" => nil,
      # TODO: Figure out what I need so I can remove select *
      # START OF MY ALIASES.
      "task_id" => 124_28,
      "task_status" => change_data_task_status,
      "request_issue_update_time" => "2023-10-19 22:47:16.233187",
      "decision_description" => "granting clothing allowance",
      "request_issue_benefit_type" => "vha",
      "request_issue_update_id" => 7,
      "actual_request_issue_id" => 4008,
      "request_issue_created_at" => "2023-10-19 22:45:43.108934",
      "intake_completed_at" => "2023-10-19 22:39:14.270897",
      "update_user_name" => "Tyler User",
      "intake_user_name" => "Monte Mann",
      "update_user_station_id" => "101",
      "intake_user_station_id" => "741",
      "decision_user_name" => nil,
      "decision_user_station_id" => nil,
      "decision_created_at" => "2023-10-19 22:48:25.281657",
      "intake_user_id" => 200_000_601_2,
      "decision_user_id" => nil,
      "update_user_id" => 3992,
      "event_user_name" => change_data_event_user_name,
      "event_date" => change_data_event_date
    }
  end

  let(:event_type) { :added_issue }
  let(:change_data_task_status) { "completed" }
  let(:change_data_claim_type) { "HigherLevelReview" }
  let(:change_data_event_user_name) { nil }
  let(:change_data_event_date) { nil }

  let(:event_attribute_data) do
    {
      assigned_at: "2023-10-19 22:47:16.222148",
      benefit_type: "vha",
      claim_type: "HigherLevelReview",
      claimant_name: "Bob Smithboehm",
      days_waiting: 11,
      decision_date: "2023-05-31",
      decision_description: "granting clothing allowance",
      disposition: "Granted",
      disposition_date: "2023-10-19",
      event_date: nil,
      event_type: event_type,
      event_user_id: nil,
      event_user_name: nil,
      intake_completed_date: nil,
      issue_description: "Clothing allowance no decision date",
      issue_type: "Clothing Allowance",
      task_id: 124_28,
      task_status: "completed",
      user_facility: nil,
      veteran_file_number: "000100022",
      # TODO: Does this even matter? or should this be the event_date? It's technically different
      withdrawal_request_date: "2023-10-19 22:47:16.233187"
    }
  end

  let(:intake_event_data) do
    {
      event_date: change_data["intake_completed_at"],
      event_user_name: change_data["intake_user_name"],
      user_facility: change_data["intake_user_station_id"],
      event_user_id: change_data["intake_user_id"]
    }
  end

  let(:update_event_data) do
    {
      event_date: change_data["request_issue_created_at"],
      event_user_name: change_data["update_user_name"],
      user_facility: change_data["update_user_station_id"],
      event_user_id: change_data["update_user_id"]
    }
  end

  describe "class methods" do
    describe ".from_change_data" do
      subject { described_class.from_change_data(event_type, change_data) }

      context "when the event type is valid" do
        let(:event_type) { :incomplete }

        it "should create an instance and not raise an error" do
          claim_history_event = subject

          expect_attributes(claim_history_event, event_attribute_data)
        end
      end

      context "when the event type is invalid" do
        let(:event_type) { :invalid_event }
        it "should raise InvalidEventType error" do
          expect { subject }.to raise_error(InvalidEventType)
        end
      end
    end

    describe ".create_completed_disposition_event" do
      let(:event_type) { :completed_disposition }

      subject { described_class.create_completed_disposition_event(change_data) }

      context "with dispostion" do
        let(:new_event_data) do
          {
            event_date: change_data["decision_created_at"],
            event_user_name: change_data["decision_user_name"],
            user_facility: change_data["decision_user_station_id"],
            event_user_id: change_data["decision_user_id"]
          }
        end

        it "should create a completed_disposition event" do
          expect_attributes(subject, event_attribute_data.merge(new_event_data))
        end
      end

      context "without dispostion" do
        before do
          change_data["disposition"] = nil
        end

        it "should not create a completed_disposition event" do
          expect(subject).to eq(nil)
        end
      end
    end

    describe ".create_claim_creation_event" do
      let(:event_type) { :claim_creation }

      subject { described_class.create_claim_creation_event(change_data) }

      it "should create a claim creation event" do
        expect_attributes(subject, event_attribute_data.merge(intake_event_data))
      end
    end

    describe ".create_status_events" do
      let(:task) { create(:task) }

      subject { described_class.create_status_events(change_data) }

      context "if the task status was assigned -> completed" do
        before do
          change_data["task_id"] = task.id
          task.completed!
        end

        it "should create a :completed status event" do
          event = subject[0]
          expect(event.event_type).to eq(:completed)
          expect(event.task_id).to eq(task.id)
          expect(event.event_user_name).to eq("System")
          expect(event.event_date).to eq(task.versions[0].changeset["updated_at"][1].iso8601)
        end
      end

      context "if the task status was assigned -> on_hold during intake then -> completed" do
        before do
          change_data["task_id"] = task.id
          task.on_hold!
          task.completed!
        end

        it "should generate two status events" do
          events = subject
          on_hold_event = events[0]
          completed_event = events[1]

          expect(events.count).to eq(2)
          # on hold event
          expect(on_hold_event.event_type).to eq(:incomplete)
          expect(on_hold_event.task_id).to eq(task.id)
          expect(on_hold_event.event_user_name).to eq("System")
          expect(on_hold_event.event_date).to eq(task.versions.first.changeset["updated_at"][1].iso8601)

          # Completed event
          expect(completed_event.event_type).to eq(:completed)
          expect(completed_event.task_id).to eq(task.id)
          expect(completed_event.event_user_name).to eq("System")
          expect(completed_event.event_date).to eq(task.versions.last.changeset["updated_at"][1].iso8601)
        end
      end

      context "if the task has no versions" do
        let(:change_data_task_status) { "assigned" }

        before do
          change_data["task_id"] = task.id
        end

        it "should create an event of the current task status which should be assigned" do
          event = subject[0]
          expect(event.event_type).to eq(:in_progress)
          expect(event.task_id).to eq(task.id)
          expect(event.event_user_name).to eq("System")
          expect(event.event_date).to eq(change_data["intake_completed_at"])
        end
      end
    end

    describe ".create_issue_events" do
      subject { described_class.create_issue_events(change_data) }

      let(:request_issue_id) { 4008 }

      let!(:request_issue) do
        create(:request_issue,
               id: request_issue_id,
               nonrating_issue_category: "Updated issue",
               nonrating_issue_description: "Updated issue description",
               decision_date: Time.zone.today,
               # This attribute has to match within 15 seconds of the request issues update to guess the event type
               decision_date_added_at: DateTime.parse(change_data["request_issue_update_time"]))
      end

      context "when there is an edited issue id with a matching added_decision_date_added_at time" do
        it "should create an added_decision_date event" do
          event = subject[0]
          expect(event.event_type).to eq(:added_decision_date)
          expect(event.event_date).to eq(change_data["request_issue_update_time"])
          expect(event.event_user_name).to eq(change_data["update_user_name"])
          expect(event.event_user_id).to eq(change_data["update_user_id"])
          expect(event.decision_date).to eq(request_issue.decision_date)
        end
      end

      context "when there is a withdrawn issue id in the withdrawn request issue ids" do
        let(:request_issue_id) { 4009 }

        before do
          change_data["edited_request_issue_ids"] = "{}"
          change_data["withdrawn_request_issue_ids"] = "{#{request_issue_id}}"
        end

        it "should create a :withdrew_issue event" do
          event = subject[0]
          expect(event.event_type).to eq(:withdrew_issue)
          expect(event.event_date).to eq(change_data["request_issue_update_time"])
          expect(event.event_user_name).to eq(change_data["update_user_name"])
          expect(event.event_user_id).to eq(change_data["update_user_id"])
          expect(event.decision_date).to eq(request_issue.decision_date)
        end
      end

      context "when there are more before request issue ids than after request issue ids" do
        let(:request_issue_id) { 4009 }

        before do
          change_data["after_request_issue_ids"] = "{}"
          change_data["before_request_issue_ids"] = "{#{request_issue_id}}"
        end

        it "should create a :removed_issue event" do
          event = subject[0]
          expect(event.event_type).to eq(:removed_issue)
          expect(event.event_date).to eq(change_data["request_issue_update_time"])
          expect(event.event_user_name).to eq(change_data["update_user_name"])
          expect(event.event_user_id).to eq(change_data["update_user_id"])
          expect(event.decision_date).to eq(request_issue.decision_date)
        end
      end

      context "when there are two withdrawn request_ids in the same update" do
        let(:request_issue_id) { 4009 }

        let!(:request_issue2) do
          create(:request_issue,
                 id: 4007,
                 nonrating_issue_category: "Updated issue",
                 nonrating_issue_description: "Updated issue description",
                 decision_date: Time.zone.today,
                 # This attribute has to match within 15 seconds of the request issues update to guess the event type
                 decision_date_added_at: DateTime.parse(change_data["request_issue_update_time"]))
        end

        before do
          change_data["edited_request_issue_ids"] = "{}"
          change_data["withdrawn_request_issue_ids"] = "{#{request_issue_id},4007}"
        end

        it "should create two :withdrew_issue events" do
          events = subject
          event1 = events[0]
          event2 = events[1]
          expect(events.count).to eq(2)
          # First withdraw
          expect(event1.event_type).to eq(:withdrew_issue)
          expect(event1.issue_type).to eq(request_issue.nonrating_issue_category)
          expect(event1.issue_description).to eq(request_issue.nonrating_issue_description)

          # Second withdraw
          expect(event2.event_type).to eq(:withdrew_issue)
          expect(event2.issue_type).to eq(request_issue2.nonrating_issue_category)
          expect(event2.issue_description).to eq(request_issue2.nonrating_issue_description)
        end
      end
    end

    describe ".create_add_issue_event" do
      let(:event_type) { :added_issue }

      subject { described_class.create_add_issue_event(change_data) }

      context "if the request issue was added during intake" do
        before do
          # The example change_data request_issue was added during an update so adjust the time to match the intake
          change_data["request_issue_created_at"] = change_data["intake_completed_at"]
        end

        it "should create an added issue event with intake event data" do
          expect_attributes(subject, event_attribute_data.merge(intake_event_data))
        end
      end

      context "if the request issue was added during a request issues update" do
        # The base change_data was added during an update so no data updates are neccesary
        it "should create an added issue event with intake event data" do
          expect_attributes(subject, event_attribute_data.merge(update_event_data))
        end
      end
    end

    describe "helper class methods" do
      describe ".retrieve_issue_data" do
        let(:request_issue) do
          create(
            :request_issue,
            nonrating_issue_category: "Issue Category",
            nonrating_issue_description: "Issue description",
            decision_date: Time.zone.today,
            # Round this because it's apparently imprecise when saving to the DB.
            decision_date_added_at: Time.zone.now.round
          )
        end

        let(:request_issue_id) { request_issue.id }

        let(:request_issue_hash) do
          {
            "nonrating_issue_category" => request_issue.nonrating_issue_category,
            "nonrating_issue_description" => request_issue.nonrating_issue_description,
            "decision_date" => request_issue.decision_date,
            "decision_date_added_at" => request_issue.decision_date_added_at.iso8601
          }
        end

        subject { described_class.send(:retrieve_issue_data, request_issue_id) }

        it "should return a hash with values retrieved from the found request issue" do
          expect(subject).to eq(request_issue_hash)
        end

        context "the request issue does not exist" do
          let(:request_issue_id) { 9999 }

          it "should return nil" do
            expect(subject).to eq(nil)
          end
        end
      end

      describe ".task_status_to_event_type" do
        subject { described_class.send(:task_status_to_event_type, task_status) }

        context "task status of in_progress" do
          let(:task_status) { "in_progress" }

          it "should return an in_progress symbol" do
            expect(subject).to eq(:in_progress)
          end
        end

        context "task status of assigned" do
          let(:task_status) { "assigned" }

          it "should return an in_progress symbol" do
            expect(subject).to eq(:in_progress)
          end
        end

        context "task status of on_hold" do
          let(:task_status) { "on_hold" }

          it "should return an incomplete symbol" do
            expect(subject).to eq(:incomplete)
          end
        end

        context "task status of completed" do
          let(:task_status) { "completed" }

          it "should return a completed symbol" do
            expect(subject).to eq(:completed)
          end
        end
      end

      describe ".event_from_version" do
        let(:task) { create(:task) }

        before do
          task.completed!
        end

        let(:version) { task.versions.first }
        let(:version_index) { 1 }

        subject { described_class.send(:event_from_version, version, version_index, change_data) }

        it "should return a completed status event from the version at index 1" do
          event = subject
          expect(event.event_type).to eq(:completed)
          expect(event.event_date).to eq(version.changeset["updated_at"][version_index].iso8601)
          expect(event.event_user_name).to eq("System")
        end

        context "index of 0" do
          let(:version_index) { 0 }

          it "should return an in progress status event from the version at index 0" do
            event = subject
            expect(event.event_type).to eq(:in_progress)
            expect(event.event_date).to eq(version.changeset["updated_at"][version_index].iso8601)
            expect(event.event_user_name).to eq("System")
          end
        end
      end

      describe ".intake_event_hash" do
        let(:event_hash) do
          {
            "event_date" => change_data["intake_completed_at"],
            "event_user_name" => change_data["intake_user_name"],
            "user_facility" => change_data["intake_user_station_id"],
            "event_user_id" => change_data["intake_user_id"]
          }
        end

        subject { described_class.send(:intake_event_hash, change_data) }

        it "should create an intake event data hash from the intake_data in the change_data" do
          expect(subject).to eq(event_hash)
        end
      end

      describe ".update_event_hash" do
        let(:event_hash) do
          {
            "event_user_name" => change_data["update_user_name"],
            "user_facility" => change_data["update_user_station_id"],
            "event_user_id" => change_data["update_user_id"]
          }
        end

        subject { described_class.send(:update_event_hash, change_data) }

        it "should create an intake event data hash from the intake_data in the change_data" do
          expect(subject).to eq(event_hash)
        end
      end
    end
  end

  describe "instance methods" do
    let(:event_instance) { described_class.new(event_type, change_data) }

    describe "public methods" do
      describe "initialize" do
        subject { event_instance }

        context "when the event type is invalid" do
          let(:event_type) { :invalid_event }
          it "should raise InvalidEventType error" do
            expect { subject }.to raise_error(InvalidEventType)
          end
        end

        context "when the event type is valid" do
          let(:event_type) { :incomplete }

          it "should create an instance and not raise an error" do
            expect_attributes(subject, event_attribute_data)
          end
        end
      end

      describe ".to_csv_array" do
        subject { event_instance.to_csv_array }

        let(:expected_array) do
          [
            event_instance.veteran_file_number, event_instance.claimant_name, event_instance.task_url,
            event_instance.readable_task_status, event_instance.days_waiting, event_instance.readable_claim_type,
            event_instance.user_facility, event_instance.readable_user_name,
            event_instance.readable_event_date, event_instance.readable_event_type,
            event_instance.send(:issue_or_status_information), event_instance.send(:disposition_information)
          ]
        end

        it "returns an array with the expected values" do
          expect(subject).to eq(expected_array)
        end
      end

      describe ".task_url" do
        subject { event_instance.task_url }

        let(:expected_url) { "https://www.caseflowdemo.com/decision_reviews/vha/tasks/#{event_instance.task_id}" }

        it "returns a task url with the id of the task in the event" do
          expect(subject).to eq(expected_url)
        end
      end

      describe ".readable_task_status" do
        subject { event_instance.readable_task_status }

        context "when the status is completed" do
          it "readable status of completed" do
            expect(subject).to eq("completed")
          end
        end

        context "when the status is assigned" do
          let(:change_data_task_status) { "assigned" }

          it "readable status of in progress" do
            expect(subject).to eq("in progress")
          end
        end

        context "when the status is in_progress" do
          let(:change_data_task_status) { "in_progress" }

          it "readable status of in progress" do
            expect(subject).to eq("in progress")
          end
        end

        context "when the status is on_hold" do
          let(:change_data_task_status) { "on_hold" }

          it "readable status of incomplete" do
            expect(subject).to eq("incomplete")
          end
        end
      end

      describe ".readable_claim_type" do
        subject { event_instance.readable_claim_type }

        context "when the claim type is HigherLevelReview" do
          it "readable claim type of Higher-Level Review" do
            expect(subject).to eq("Higher-Level Review")
          end
        end

        context "when the claim type is SupplementalClaim" do
          let(:change_data_claim_type) { "SupplementalClaim" }

          it "readable claim type of Supplemental Claim" do
            expect(subject).to eq("Supplemental Claim")
          end
        end
      end

      describe ".readable_user_name" do
        subject { event_instance.readable_user_name }

        context "when the event user name is System" do
          let(:change_data_event_user_name) { "System" }

          it "readable user name of System" do
            expect(subject).to eq("System")
          end
        end

        context "when the event user name is a first and last name" do
          let(:change_data_event_user_name) { "Bob Smith" }

          it "readable user name of (First initial. Last Name) e.g. Bob Smith -> B. Smith" do
            expect(subject).to eq("B. Smith")
          end
        end
      end

      describe ".readable_event_date" do
        subject { event_instance.readable_event_date }

        let(:change_data_event_date) { "2023-10-26T22:25:04Z" }

        it "readable event date of the form m/d/yyyy" do
          expect(subject).to eq("10/26/2023")
        end
      end

      describe ".readable_decision_date" do
        subject { event_instance.readable_decision_date }

        it "readable decision date of the form m/d/yyyy" do
          expect(subject).to eq("5/31/2023")
        end
      end

      describe ".readable_disposition_date" do
        subject { event_instance.readable_disposition_date }

        it "readable disposition date of the form m/d/yyyy" do
          expect(subject).to eq("10/19/2023")
        end
      end

      describe ".readable_event_type" do
        subject { event_instance.readable_event_type }

        # Copy of the hash from claim_history_event.rb
        # TODO: Possibly move this to a json somewhere or utils
        event_types = {
          in_progress: "Claim status - In Progress",
          incomplete: "Claim status - Incomplete",
          completed: "Claim closed",
          claim_creation: "Claim created",
          completed_disposition: "Completed disposition",
          added_issue: "Added Issue",
          withdrew_issue: "Withdrew issue",
          removed_issue: "Removed issue",
          added_decision_date: "Added decision date"
        }

        event_types.each do |event_type, readable_name|
          context "#{event_type} event type" do
            let(:event_type) { event_type }

            it "returns the readable name for #{event_type}" do
              expect(subject).to eq(readable_name)
            end
          end
        end
      end

      describe ".issue_event?" do
        subject { event_instance.issue_event? }

        context "for a non issue event" do
          let(:event_type) { :claim_creation }

          it "should return false" do
            expect(subject).to eq(false)
          end
        end

        issue_events = [:completed_disposition, :added_issue, :withdrew_issue, :removed_issue, :added_decision_date]
        issue_events.each do |event_type|
          context "#{event_type} event type" do
            let(:event_type) { event_type }

            it "returns true for: #{event_type}" do
              expect(subject).to eq(true)
            end
          end
        end
      end

      describe ".disposition_event?" do
        subject { event_instance.disposition_event? }

        context "for a non disposition event" do
          let(:event_type) { :claim_creation }

          it "should return false" do
            expect(subject).to eq(false)
          end
        end

        context "for a disposition event" do
          let(:event_type) { :completed_disposition }

          it "should return true" do
            expect(subject).to eq(true)
          end
        end
      end

      describe ".status_event?" do
        subject { event_instance.status_event? }

        context "for a non status event" do
          let(:event_type) { :added_issue }

          it "should return false" do
            expect(subject).to eq(false)
          end
        end

        status_events = [:in_progress, :incomplete, :completed, :claim_creation]
        status_events.each do |event_type|
          context "#{event_type} event type" do
            let(:event_type) { event_type }

            it "returns true for: #{event_type}" do
              expect(subject).to eq(true)
            end
          end
        end
      end
    end

    describe "private methods" do
      describe ".days_waiting_helper" do
        before do
          Timecop.freeze(Time.utc(2023, 10, 30, 12, 0, 0))
        end

        after do
          Timecop.return
        end

        subject { event_instance.send(:days_waiting_helper, change_data["assigned_at"]) }

        it "should convert an iso8601 string to number of days from current date" do
          expect(subject).to eq(10)
        end
      end

      describe ".abbreviated_user_name" do
        subject { event_instance.send(:abbreviated_user_name, "Bob Smith") }

        it "should convert the name string into (First Initial. Last Name) e.g. Bob Smith -> B. Smith" do
          expect(subject).to eq("B. Smith")
        end
      end

      describe ".issue_information" do
        subject { event_instance.send(:issue_information) }

        let(:expected_issue_data) do
          [
            event_instance.issue_type,
            event_instance.issue_description,
            event_instance.readable_decision_date
          ]
        end

        context "if it is an issue event e.g. :added_issue, :withdrew_issue, :removed_issue, etc..." do
          it "should return an array of request issue information if it is an issue event" do
            expect(subject).to eq(expected_issue_data)
          end
        end

        context "if it is not an issue event" do
          let(:event_type) { :claim_creation }

          it "should return nil" do
            expect(subject).to eq(nil)
          end
        end
      end

      describe ".disposition_information" do
        subject { event_instance.send(:disposition_information) }

        let(:expected_disposition_data) do
          [
            event_instance.disposition,
            event_instance.decision_description,
            event_instance.readable_disposition_date
          ]
        end

        context "if it is a disposition event e.g. :completed_disposition" do
          let(:event_type) { :completed_disposition }

          it "should return an array of request issue information if it is an issue event" do
            expect(subject).to eq(expected_disposition_data)
          end
        end

        context "if it is not a disposition event" do
          let(:event_type) { :claim_creation }

          it "should return nil" do
            expect(subject).to eq(nil)
          end
        end
      end

      describe ".issue_or_status_information" do
        subject { event_instance.send(:issue_or_status_information) }

        context "status event" do
          let(:event_type) { :in_progress }

          it "should return a placeholder and the status description" do
            expect(subject).to eq([nil, event_instance.send(:status_description)])
          end
        end

        context "not a status event event" do
          it "should return the result of the issue information method" do
            expect(subject).to eq(event_instance.send(:issue_information))
          end
        end
      end

      describe ".status_description" do
        subject { event_instance.send(:status_description) }

        # Copy of the hash from claim_history_event.rb
        # TODO: Possibly move this to a json somewhere or utils
        status_descriptions = {
          in_progress: "Claim can be processed.",
          incomplete: "Claim cannot be processed until decision date is entered.",
          completed: "Claim closed.",
          claim_creation: "Claim created."
        }

        status_descriptions.each do |event_type, description|
          context "#{event_type} event type" do
            let(:event_type) { event_type }

            it "returns the description for the status event type: #{event_type}" do
              expect(subject).to eq(description)
            end
          end
        end
      end

      describe ".format_date_string" do
        before do
          Timecop.freeze(Time.utc(2023, 10, 30, 12, 0, 0))
        end

        after do
          Timecop.return
        end

        let(:date_param) { Time.zone.now }

        subject { event_instance.send(:format_date_string, date_param) }

        context "when the param is a ruby datetime object" do
          it "should return the date in m/d/yyyy format" do
            expect(subject).to eq("10/30/2023")
          end
        end

        context "when the param is an iso8601 datestring" do
          let(:date_param) { Time.zone.now.iso8601 }

          it "should return the date in m/d/yyyy format" do
            expect(subject).to eq("10/30/2023")
          end
        end
      end
    end
  end

  def expect_attributes(object_instance, attribute_value_pairs)
    attribute_value_pairs.each do |attribute, expected_value|
      expect(object_instance.send(attribute)).to eq(expected_value)
    end
  end
end
