# frozen_string_literal: true

require_relative "../../../app/services/claim_change_history/claim_history_service.rb"
require_relative "../../../app/services/claim_change_history/claim_history_event.rb"

describe ClaimHistoryService do
  let!(:hlr_task) { create(:higher_level_review_vha_task_with_decision) }
  let!(:sc_task) do
    create(:supplemental_claim_vha_task,
           appeal: create(:supplemental_claim,
                          :with_vha_issue,
                          :with_intake,
                          benefit_type: "vha",
                          claimant_type: :dependent_claimant))
  end
  let!(:hlr_task_with_imr) do
    create(:issue_modification_request,
           :with_higher_level_review,
           :edit_of_request,
           :update_decider,
           nonrating_issue_category: "Medical and Dental Care Reimbursement")
  end

  let!(:extra_hlr_request_issue) do
    create(:request_issue,
           nonrating_issue_category: "Camp Lejune Family Member",
           nonrating_issue_description: "Camp Lejune description",
           decision_date: nil,
           decision_review: hlr_task.appeal)
  end

  let!(:withdrew_issue) do
    create(:request_issue,
           nonrating_issue_category: "CHAMPVA",
           nonrating_issue_description: "Withdrew CHAMPVA",
           decision_date: Time.zone.today,
           decision_review: hlr_task.appeal)
  end

  let!(:request_issue_update_withdraw) do
    create(:request_issues_update,
           user: update_user,
           review: hlr_task.appeal,
           before_request_issue_ids: hlr_task.appeal.request_issues.pluck(:id),
           after_request_issue_ids: hlr_task.appeal.request_issues.pluck(:id),
           withdrawn_request_issue_ids: [withdrew_issue.id],
           edited_request_issue_ids: [])
  end

  let!(:request_issue_update_add_decision_date) do
    create(:request_issues_update,
           user: update_user2,
           review: hlr_task.appeal,
           # Make the created at time different from the request issue created at and intake times for event creation
           created_at: Time.zone.now + 1.day,
           before_request_issue_ids: hlr_task.appeal.request_issues.pluck(:id),
           after_request_issue_ids: hlr_task.appeal.request_issues.pluck(:id),
           withdrawn_request_issue_ids: [],
           edited_request_issue_ids: [extra_hlr_request_issue.id])
  end

  let(:decision_user) { create(:user, full_name: "Gaius Baelsar", css_id: "GAIUSVHA", station_id: "104") }
  let(:sc_intake_user) { create(:user, full_name: "Eleanor Reynolds", css_id: "ELENVHA", station_id: "103") }
  let(:update_user) { create(:user, full_name: "Alexander Dewitt", css_id: "ALEXVHA", station_id: "103") }
  let(:update_user2) { create(:user, full_name: "Captain Underpants", css_id: "CAPTAINVHA", station_id: "105") }
  let(:decision_issue) do
    create(:decision_issue,
           disposition: "denied",
           benefit_type: hlr_task.appeal.benefit_type,
           caseflow_decision_date: 5.days.ago.to_date)
  end
  let(:filters) { {} }
  let!(:vha_business_line) { VhaBusinessLine.singleton }

  let(:expected_hlr_event_types) do
    [
      :withdrew_issue,
      :added_issue,
      :claim_creation,
      :incomplete,
      :in_progress,
      :completed,
      :completed_disposition,
      :added_decision_date,
      :added_issue,
      :added_issue_without_decision_date,
      :completed_disposition
    ]
  end

  let(:total_event_count) { 22 }

  let(:expected_sc_event_types) do
    [
      :added_issue,
      :claim_creation,
      :in_progress
    ]
  end

  let(:expected_imr_event_types) do
    [
      :claim_creation,
      :added_issue,
      :in_progress,
      :pending,
      :addition,
      :request_edited,
      :request_approved,
      :in_progress
    ]
  end

  before do
    # Remove the versions to setup specific versions
    hlr_task.versions.each(&:delete)
    hlr_task.save
    hlr_task.reload

    PaperTrail.request(enabled: false) do
      hlr_task.assigned!
    end

    hlr_task.assigned!

    # Simulate the task status for a task that went intake -> on_hold -> assigned -> completed
    hlr_task.on_hold!

    # Setup add decision date event and added_issue_without_decision_date
    extra_hlr_request_issue.decision_date = Time.zone.today

    extra_hlr_request_issue.decision_date_added_at = request_issue_update_add_decision_date.created_at
    extra_hlr_request_issue.save

    hlr_task.assigned!

    # Setup request issues and decision issues
    decision_issue.request_issues << extra_hlr_request_issue
    hlr_task.appeal.decision_issues << decision_issue

    sc_task.appeal.intake.user = sc_intake_user
    sc_task.appeal.intake.save

    decision_issue.save
    hlr_task.appeal.save

    # Set the time and save it for days waiting filter. Should override assigned!
    hlr_task.assigned_at = 5.days.ago - 2.hours
    hlr_task.save

    # Set the task status back to completed to finish off the versions
    hlr_task.completed!

    # Set the whodunnnit of the completed version status to the decision user
    completed_version = hlr_task.versions.last
    completed_version.whodunnit = decision_user.id.to_s
    completed_version.save
  end

  describe ".build_events" do
    let(:service_instance) { described_class.new(vha_business_line, filters) }

    subject { service_instance.build_events }

    context "without filters" do
      it "should generate all the events for every task associated to the business line" do
        events = subject
        # Expect the events to be saved as an instance variable in addition to being returned
        expect(events).to eq(service_instance.events)

        # Expect to get back all the combined event types
        all_event_types = expected_hlr_event_types + expected_sc_event_types + expected_imr_event_types
        expect(events.count).to eq(total_event_count)
        expect(events.map(&:event_type)).to contain_exactly(*all_event_types)

        # Verify the issue data is correct for the completed_dispostion events
        disposition_events = events.select { |event| event.event_type == :completed_disposition }
        disposition_issue_types = ["Caregiver | Other", "Camp Lejune Family Member"]
        disposition_issue_descriptions = ["VHA - Caregiver", "Camp Lejune description"]
        disposition_user_names = ["Gaius Baelsar", "Gaius Baelsar"]
        disposition_values = %w[Granted denied]
        disposition_dates = [5.days.ago.to_date.to_s] * 2

        expect(disposition_events.map(&:issue_type)).to contain_exactly(*disposition_issue_types)
        expect(disposition_events.map(&:issue_description)).to contain_exactly(*disposition_issue_descriptions)
        expect(disposition_events.map(&:event_user_name)).to contain_exactly(*disposition_user_names)
        expect(disposition_events.map(&:disposition)).to contain_exactly(*disposition_values)
        expect(disposition_events.map(&:disposition_date)).to contain_exactly(*disposition_dates)

        # Verify the issue data is correct for all the add issue events
        added_issue_types = [*disposition_issue_types, "CHAMPVA", "Beneficiary Travel", "Caregiver | Other"]
        added_issue_descriptions = [*disposition_issue_descriptions,
                                    "Withdrew CHAMPVA",
                                    "VHA issue description ",
                                    "VHA - Caregiver"]
        added_issue_user_names = ["Lauren Roth", "Lauren Roth", "Lauren Roth", "Eleanor Reynolds", "Lauren Roth"]
        add_issue_events = events.select do |event|
          event.event_type == :added_issue || event.event_type == :added_issue_without_decision_date
        end
        expect(add_issue_events.map(&:issue_type)).to contain_exactly(*added_issue_types)
        expect(add_issue_events.map(&:issue_description)).to contain_exactly(*added_issue_descriptions)
        expect(add_issue_events.map(&:event_user_name)).to contain_exactly(*added_issue_user_names)

        # Verify the issue data is correct for the withdrew issue event
        withdrew_issue_event = events.find { |event| event.event_type == :withdrew_issue }
        expect(withdrew_issue_event.issue_type).to eq(withdrew_issue.nonrating_issue_category)
        expect(withdrew_issue_event.issue_description).to eq(withdrew_issue.nonrating_issue_description)
        expect(withdrew_issue_event.event_user_name).to eq(update_user.full_name)

        # Verify the issue data is correct for the add decision date event
        add_decision_date_event = events.find { |event| event.event_type == :added_decision_date }
        expect(add_decision_date_event.issue_type).to eq(extra_hlr_request_issue.nonrating_issue_category)
        expect(add_decision_date_event.issue_description).to eq(extra_hlr_request_issue.nonrating_issue_description)
        expect(add_decision_date_event.event_user_name).to eq(update_user2.full_name)

        # Verify that the completed status event has access to the disposition/caseflow decision date for the ui
        completed_status_event = events.find { |event| event.event_type == :completed }
        expect(completed_status_event.disposition_date).to eq(disposition_dates.first)
      end

      it "should sort by task id and event date" do
        issue = hlr_task.appeal.decision_issues.last
        issue.update(created_at: Time.zone.now - 90.days)
        events = subject

        # expect the first event to always be claim creation
        expect(events.first.event_type).to eq(:claim_creation)
        # expect the second event to be the one with the fudged far-in-the-past date
        expect(events.second.event_type).to eq(:completed_disposition)
      end
    end

    context "issue modification edge cases" do
      let!(:sc_task_with_imrs) do
        create(:supplemental_claim_vha_task,
               appeal: create(:supplemental_claim,
                              :with_vha_issue,
                              :with_intake,
                              benefit_type: "vha",
                              claimant_type: :veteran_claimant))
      end

      let(:request_issue) { sc_task_with_imrs.appeal.request_issues.first }
      let(:supplemental_claim) { sc_task_with_imrs.appeal }

      let(:starting_imr_events) do
        [:claim_creation, :added_issue, :in_progress, :removal, :pending, :addition]
      end

      let!(:issue_modification_addition) do
        create(:issue_modification_request,
               request_type: "addition",
               decision_review: supplemental_claim,
               requestor: vha_user,
               nonrating_issue_category: "CHAMPVA",
               nonrating_issue_description: "Starting issue description",
               decision_date: 5.days.ago)
      end

      let(:issue_modification_modify) do
        create(:issue_modification_request,
               request_type: "modification",
               decision_review: supplemental_claim,
               requestor: vha_user,
               request_issue: supplemental_claim.request_issues.first)
      end

      # Only generate the events for this task to keep it focused on the issue modification request events
      let!(:filters) { { task_id: [sc_task_with_imrs.id] } }

      let(:vha_admin) { create(:user, full_name: "VHA ADMIN", css_id: "VHAADMIN") }
      let(:vha_user) { create(:user, full_name: "VHA USER", css_id: "VHAUSER") }

      before do
        OrganizationsUser.make_user_admin(vha_admin, VhaBusinessLine.singleton)
        VhaBusinessLine.singleton.add_user(vha_user)
        Timecop.freeze(Time.zone.now)
      end

      after do
        Timecop.return
      end

      def create_last_addition_and_verify_events(original_events, current_events)
        new_events = current_events.dup
        Timecop.travel(2.minutes.from_now)
        addition = create(:issue_modification_request, request_type: "addition", decision_review: supplemental_claim)

        events = service_instance.build_events
        new_events.push(:addition, :pending)
        expect(events.map(&:event_type)).to contain_exactly(*original_events + new_events)

        # Approve the newest addition to make sure the in progress and approval events are correct
        Timecop.travel(2.minutes.from_now)
        addition.update!(decider: vha_admin, status: :approved, decision_reason: "Better reason2")

        events = service_instance.build_events
        new_events.push(:in_progress, :request_approved)
        expect(events.map(&:event_type)).to contain_exactly(*original_events + new_events)
      end

      it "should correctly generate temporary in progress and pending events for a single imr event" do
        events = subject
        one_imr_events = *starting_imr_events - [:removal]
        expect(events.map(&:event_type)).to contain_exactly(*one_imr_events)

        # Make an edit to the addition and make sure the events are correct
        Timecop.travel(2.minutes.from_now)
        issue_modification_addition.update!(edited_at: Time.zone.now, nonrating_issue_category: "CHAMPVA")

        # Rebuild events
        service_instance.build_events
        new_events = [:request_edited]
        expect(events.map(&:event_type)).to contain_exactly(*one_imr_events + new_events)

        # Approve the addition and make sure the events are correct
        # NOTE: This only does the issue modification events and does not create a request issue update
        Timecop.travel(2.minutes.from_now)
        issue_modification_addition.update!(decider: vha_admin, status: :approved, decision_reason: "Better reason")

        # Rebuild events
        service_instance.build_events
        new_events.push(:in_progress, :request_approved)
        expect(events.map(&:event_type)).to contain_exactly(*one_imr_events + new_events)

        # Create another addition IMR to verify that the event sequence works through one more iteration
        create_last_addition_and_verify_events(one_imr_events, new_events)
      end

      it "should correctly generate events for an imr that is cancelled while another is added" do
        events = subject
        one_imr_events = *starting_imr_events - [:removal]
        expect(events.map(&:event_type)).to contain_exactly(*one_imr_events)

        # Cancel the addition IMR at the same time as creating a new issue modification request to
        # modify the existing request issue on the supplemental claim
        Timecop.travel(2.minutes.from_now)
        ActiveRecord::Base.transaction do
          issue_modification_addition.update!(status: "cancelled")
          issue_modification_modify
        end

        # Rebuild events
        service_instance.build_events
        new_events = [:modification, :request_cancelled]
        expect(events.map(&:event_type)).to contain_exactly(*one_imr_events + new_events)

        # Approve the modification to verify that it create a new in progress event and a denied event
        Timecop.travel(2.minutes.from_now)
        issue_modification_modify.update!(decider: vha_admin, status: :denied, decision_reason: "Better reason")

        # Rebuild events
        service_instance.build_events
        new_events.push(:in_progress, :request_denied)
        expect(events.map(&:event_type)).to contain_exactly(*one_imr_events + new_events)

        # Create another addition IMR to verify that the event sequence works through one more iteration
        create_last_addition_and_verify_events(one_imr_events, new_events)
      end

      it "should correctly track the previous version data for multiple IMR edits" do
        events = subject
        one_imr_events = *starting_imr_events - [:removal]
        expect(events.map(&:event_type)).to contain_exactly(*one_imr_events)

        # Edit several fields to create a new version of the IMR
        Timecop.travel(2.minutes.from_now)
        issue_modification_addition.update!(nonrating_issue_category: "Other",
                                            nonrating_issue_description: "Edited description 1",
                                            edited_at: Time.zone.now)

        # Rebuild events
        service_instance.build_events
        new_events = [:request_edited]
        expect(events.map(&:event_type)).to contain_exactly(*one_imr_events + new_events)

        # Edit several fields to create a new version of the IMR
        Timecop.travel(2.minutes.from_now)
        issue_modification_addition.update!(nonrating_issue_description: "Edited description 2",
                                            edited_at: Time.zone.now)

        # Rebuild events
        service_instance.build_events
        new_events.push(:request_edited)
        expect(events.map(&:event_type)).to contain_exactly(*one_imr_events + new_events)

        # Verify that each of the edited events has the information from the previous version
        edited_events = events.select { |event| event.event_type == :request_edited }

        first_edit = edited_events.first
        second_edit = edited_events.last

        expect(first_edit).to have_attributes(
          new_issue_description: "Edited description 1",
          new_issue_type: "Other",
          previous_issue_description: "Starting issue description",
          previous_issue_type: "CHAMPVA"
        )

        expect(second_edit).to have_attributes(
          new_issue_description: "Edited description 2",
          new_issue_type: "Other",
          previous_issue_description: "Edited description 1",
          previous_issue_type: "Other"
        )
      end

      context "starting with two imrs" do
        let!(:issue_modification_removal) do
          create(:issue_modification_request,
                 request_type: "removal",
                 request_issue: request_issue,
                 decision_review: supplemental_claim)
        end

        it "should correctly generate temporary in progress events for two imrs created at the same time" do
          events = subject
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events)

          # Deny the removal and make sure the events are correct
          Timecop.travel(2.minutes.from_now)
          issue_modification_removal.update!(decider: vha_admin, status: :denied, decision_reason: "Just cause")

          # Rebuild events
          service_instance.build_events
          new_events = [:request_denied]
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events + new_events)

          # Approve the addition and make sure the events are correct
          # NOTE: This only does the issue modification events and does not create a request issue update
          Timecop.travel(2.minutes.from_now)
          issue_modification_addition.update!(decider: vha_admin, status: :approved, decision_reason: "Better reason")

          # Rebuild events
          service_instance.build_events
          new_events.push(:in_progress, :request_approved)
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events + new_events)

          # Create another addition IMR to verify that the event sequence works through one more iteration
          create_last_addition_and_verify_events(starting_imr_events, new_events)
        end

        it "should correctly generate temporary in progress events for two imrs decided at the same time" do
          events = subject
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events)

          # Deny the removal and approve the addition and make sure the events are correct
          Timecop.travel(2.minutes.from_now)
          ActiveRecord::Base.transaction do
            issue_modification_removal.update!(decider: vha_admin, status: :denied, decision_reason: "Just cause")
            issue_modification_addition.update!(decider: vha_admin, status: :approved, decision_reason: "Better reason")
          end

          # Rebuild events
          service_instance.build_events
          new_events = [:request_denied, :request_approved, :in_progress]
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events + new_events)

          # Create another addition IMR to verify that the event sequence works through one more iteration
          Timecop.travel(2.minutes.from_now)
          addition2 = create(:issue_modification_request, request_type: "addition", decision_review: supplemental_claim)

          service_instance.build_events
          new_events.push(:addition, :pending)
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events + new_events)

          # Approve the newest addition to make sure the in progress and approval events are correct
          Timecop.travel(2.minutes.from_now)
          addition2.update!(decider: vha_admin, status: :approved, decision_reason: "Better reason2")

          service_instance.build_events
          new_events.push(:in_progress, :request_approved)
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events + new_events)

          # Create another addition IMR to verify that the event sequence works through one more iteration
          create_last_addition_and_verify_events(starting_imr_events, new_events)
        end

        it "should correctly generate temporary in progress events for two imrs with one cancelled in reverse order" do
          events = subject
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events)

          # Approve the addition and make sure the events are correct
          # NOTE: This only does the issue modification events and does not create a request issue update
          Timecop.travel(2.minutes.from_now)
          issue_modification_addition.update!(decider: vha_admin, status: :approved, decision_reason: "Better reason")

          # Rebuild events
          service_instance.build_events
          new_events = [:request_approved]
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events + new_events)

          # Cancel the removal and make sure the events are correct
          Timecop.travel(2.minutes.from_now)
          issue_modification_removal.update!(decider: vha_admin, status: :cancelled, decision_reason: "Just cause")

          # Rebuild events
          service_instance.build_events
          new_events.push(:request_cancelled, :in_progress)
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events + new_events)

          # Create another addition IMR to verify that the event sequence works through one more iteration
          create_last_addition_and_verify_events(starting_imr_events, new_events)
        end

        it "when an imr is cancelled at the same time and another is created" do
          events = subject
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events)

          # Approve the addition and make sure the events are correct
          # NOTE: This only does the issue modification events and does not create a request issue update
          Timecop.travel(2.minutes.from_now)
          issue_modification_addition.update!(decider: vha_admin, status: :approved, decision_reason: "Better reason")

          # Rebuild events
          service_instance.build_events
          new_events = [:request_approved]
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events + new_events)

          # Cancel the removal and add a new approval at the same time
          Timecop.travel(2.minutes.from_now)
          addition2 = nil
          ActiveRecord::Base.transaction do
            issue_modification_removal.update!(decider: vha_admin, status: :cancelled, decision_reason: "Just cause")
            addition2 = create(:issue_modification_request,
                               request_type: "addition",
                               decision_review: supplemental_claim)
          end

          # Rebuild events
          service_instance.build_events
          new_events.push(:request_cancelled, :addition)
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events + new_events)

          # Approve the newest addition to make sure the in progress and approval events are correct
          Timecop.travel(2.minutes.from_now)
          addition2.update!(decider: vha_admin, status: :approved, decision_reason: "Better reason2")

          service_instance.build_events
          new_events.push(:in_progress, :request_approved)
          expect(events.map(&:event_type)).to contain_exactly(*starting_imr_events + new_events)

          # Create another addition IMR to verify that the event sequence works through one more iteration
          create_last_addition_and_verify_events(starting_imr_events, new_events)
        end
      end

      context "with multiple text edit in for a withdrawal event" do
        let!(:issue_modification_withdrawal) do
          create(:issue_modification_request,
                 :withdrawal,
                 request_issue: request_issue,
                 decision_review: supplemental_claim,
                 request_reason: "first comment in the array",
                 nonrating_issue_description: "first nonrating description")
        end

        let!(:issue_modification_edit_of_request_first) do
          issue_modification_withdrawal.nonrating_issue_description = "this is first update"
          issue_modification_withdrawal.updated_at = Time.zone.today
          issue_modification_withdrawal.save!
        end

        let!(:issue_modification_edit_of_request_second) do
          issue_modification_withdrawal.nonrating_issue_description = "this is Second update"
          issue_modification_withdrawal.withdrawal_date = Time.zone.today - 12.days
          issue_modification_withdrawal.updated_at = Time.zone.today
          issue_modification_withdrawal.save!
        end

        it "should have two request of edit event and a withdrawal event" do
          events = service_instance.build_events
          starting_event_without_removal = *starting_imr_events - [:removal]
          new_events = [:withdrawal, :request_edited, :request_edited]
          expect(events.map(&:event_type)).to contain_exactly(*starting_event_without_removal + new_events)
        end
      end
    end

    context "with filters" do
      context "with task_id filter" do
        let(:filters) { { task_id: sc_task.id } }

        it "should only return the events for tasks that match the task id filter" do
          subject
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_sc_event_types)
        end

        context "with no filter matches" do
          let(:filters) { { task_id: [998, 999] } }

          it "should return no events" do
            subject
            expect(service_instance.events).to eq([])
          end
        end

        context "with multiple filters for task id and event" do
          let(:filters) { { task_id: sc_task.id, events: [:added_issue, :claim_creation] } }

          it "should only return the filtered events for the specific task ids" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(:added_issue, :claim_creation)
          end
        end
      end

      context "with claim_type filter" do
        let(:filters) { { claim_type: "HigherLevelReview" } }

        it "should only return events for tasks that match the claim type filter" do
          subject
          expect(service_instance.events.map(&:event_type)).to contain_exactly(
            *expected_hlr_event_types,
            *expected_imr_event_types
          )
        end

        context "with no filter matches" do
          let(:filters) { { claim_type: ["Appeal"] } }

          it "should return no events" do
            subject
            expect(service_instance.events).to eq([])
          end
        end
      end

      context "with task_status filter" do
        let(:filters) { { task_status: ["assigned"] } }

        it "should only return events for the tasks that match the task status filter" do
          subject
          expect(service_instance.events.map(&:event_type)).to contain_exactly(
            *expected_sc_event_types,
            *expected_imr_event_types
          )
        end

        context "with no filter matches" do
          let(:filters) { { task_status: ["on_hold"] } }

          it "should return no events" do
            subject
            expect(service_instance.events).to eq([])
          end
        end
      end

      context "with dispositions filter" do
        let(:filters) { { dispositions: ["Granted"] } }

        it "should only return events for the tasks that match the dispositions filter" do
          subject

          expected_event_types = [
            :added_decision_date,
            :added_issue,
            :completed_disposition
          ]
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_event_types)
        end

        context "with no filter matches" do
          let(:filters) { { dispositions: ["Dismissed"] } }

          it "should return no events" do
            subject
            expect(service_instance.events).to eq([])
          end
        end

        context "with Blank filter" do
          let(:filters) { { dipositions: ["Blank"] } }

          it "should return events without a disposition" do
            subject
            expect(service_instance.events.count).to eq(total_event_count)
          end
        end
      end

      context "with issue_types filter" do
        let(:filters) { { issue_types: ["Caregiver | Other"] } }

        it "should only return events for the tasks that match the issue types filter" do
          subject
          expected_event_types = [
            :added_issue,
            :completed_disposition,
            :added_issue,
            :request_edited
          ]
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_event_types)
        end

        context "with no filter matches" do
          let(:filters) { { issue_types: ["Foreign Medical Program"] } }

          it "should return no events" do
            subject
            expect(service_instance.events).to eq([])
          end
        end

        context "with multiple issue types" do
          let(:filters) { { issue_types: ["Caregiver | Other", "CHAMPVA"] } }

          it "should only return events for the tasks that match the issue types filter" do
            subject
            expected_event_types = [
              :added_issue,
              :completed_disposition,
              :added_issue,
              :withdrew_issue,
              :added_issue,
              :request_edited
            ]
            expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_event_types)
          end
        end
      end

      context "with event_type filter " do
        let(:filters) { { events: [:added_issue, :completed_disposition] } }

        it "should only return events with the specified event types" do
          subject
          expected_event_types = [
            :added_issue,
            :added_issue,
            :added_issue,
            :added_issue,
            :completed_disposition,
            :completed_disposition
          ]
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_event_types)
        end

        context "with no filter matches" do
          let(:filters) { { events: [:invalid_event_type] } }

          it "should return no events" do
            subject
            expect(service_instance.events).to eq([])
          end
        end

        context "with multiple filters for claim_type and event" do
          let(:filters) { { events: [:added_issue, :completed_disposition], claim_type: "SupplementalClaim" } }

          it "should only return the filtered events for the specific task ids" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(:added_issue)
          end
        end
      end

      context "with timing filter" do
        context "with before timing" do
          let(:filters) { { timing: { range: "before", start_date: (Time.zone.now + 30.days).iso8601 } } }

          it "should only return events for task that are before the start_date in the filter" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(
              *expected_hlr_event_types,
              *expected_sc_event_types,
              *expected_imr_event_types
            )
          end
        end

        context "with after timing" do
          before do
            # Change the intake date for claim created and two of the issues to more than 7 days
            # To remove them from the event list
            new_time = 25.days.ago
            hlr_task.appeal.intake.completed_at = new_time
            issue = hlr_task.appeal.request_issues.first
            issue.created_at = new_time
            extra_hlr_request_issue.created_at = new_time
            issue.save
            extra_hlr_request_issue.save
            hlr_task.appeal.intake.save
          end
          let(:filters) { { timing: { range: "after", start_date: (Time.zone.now - 7.days).iso8601 } } }

          it "should only return events for task that are after the start_date in the filter" do
            subject
            filtered_hlr_event_types = [
              *(expected_hlr_event_types - [:added_issue, :claim_creation, :added_issue_without_decision_date]),
              :added_issue
            ]
            expect(service_instance.events.map(&:event_type)).to contain_exactly(
              *filtered_hlr_event_types,
              *expected_sc_event_types,
              *expected_imr_event_types
            )
          end
        end

        context "with between timing" do
          before do
            hlr_task.appeal.intake.completed_at = 7.days.ago
            hlr_task.appeal.intake.save
          end
          let(:filters) do
            {
              timing: {
                range: "between",
                start_date: (Time.zone.now - 5.days).iso8601,
                end_date: (Time.zone.now + 5.days).iso8601
              }
            }
          end

          it "should only return events for task that are between the start and end date in the filter" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(
              *(expected_hlr_event_types - [:claim_creation]),
              *expected_sc_event_types,
              *expected_imr_event_types
            )
          end

          context "with between and task status" do
            let(:filters) do
              {
                timing: {
                  range: "between",
                  start_date: (Time.zone.now - 5.days).iso8601,
                  end_date: (Time.zone.now + 5.days).iso8601
                },
                task_status: ["completed"]
              }
            end

            it "should only return events between the dates and has a completed task status in the filter" do
              subject
              # The before block adds one additional completed event due to the setup code
              expect(service_instance.events.map(&:event_type)).to contain_exactly(
                *(expected_hlr_event_types - [:claim_creation, :completed]), :completed
              )
            end
          end
        end

        context "last 7 days filter" do
          let(:filters) { { timing: { range: "last_7_days" } } }

          before do
            new_time = 5.days.ago
            issue = hlr_task.appeal.request_issues.first
            hlr_task.appeal.intake.completed_at = new_time
            issue.created_at = new_time
            extra_hlr_request_issue.created_at = new_time
            issue.save
            extra_hlr_request_issue.save
            hlr_task.appeal.intake.save
          end

          it "should only return events that have occured in the last 7 days" do
            subject
            # Only check for these 3 since they were set in the before block. This is a bandaid for not using timecop
            expect(service_instance.events.map(&:event_type)).to include(:claim_creation, :added_issue, :added_issue)
          end
        end

        context "last 30 days filter" do
          let(:filters) { { timing: { range: "last_30_days" } } }

          before do
            # Change the intake date for claim created and one of the issues to more than 30 days
            # To remove them from the event list
            new_time = 25.days.ago
            issue = hlr_task.appeal.request_issues.first
            hlr_task.appeal.intake.completed_at = new_time
            issue.created_at = new_time
            # Make this one less than 30 so it still appears with a different date than it originally had
            extra_hlr_request_issue.created_at = 35.days.ago
            issue.save
            extra_hlr_request_issue.save
            hlr_task.appeal.intake.save
          end

          it "should only return events that have occured in the last 30 days" do
            subject
            # Only check for these two since they were set in the before block. This is a bandaid for not using timecop
            expect(service_instance.events.map(&:event_type)).to include(:claim_creation, :added_issue)
          end
        end

        context "last 365 days filter" do
          let(:filters) { { timing: { range: "last_365_days" } } }

          before do
            # Change the intake date for claim created and one of the issues to less than 365 days
            # To make sure they are in the event list
            new_time = 35.days.ago
            issue = hlr_task.appeal.request_issues.first
            hlr_task.appeal.intake.completed_at = new_time
            issue.created_at = new_time
            # Make this one more than 365 days to remove it from the list
            extra_hlr_request_issue.created_at = 13.months.ago
            issue.save
            extra_hlr_request_issue.save
            hlr_task.appeal.intake.save
          end

          it "should only return events that have occured in the last 365 days" do
            subject
            # Only check for these two since they were set in the before block. This is a bandaid for not using timecop
            expect(service_instance.events.map(&:event_type)).to include(:claim_creation, :added_issue)
          end
        end

        context "with no filter matches" do
          let(:filters) { { timing: { range: "after", start_date: (Time.zone.now + 30.days).iso8601 } } }

          it "should return no events" do
            subject
            expect(service_instance.events).to eq([])
          end
        end

        context "when the range does not match the valid ranges" do
          let(:filters) { { timing: { range: "None", start_date: (Time.zone.now + 30.days).iso8601 } } }

          it "should return all events" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_hlr_event_types,
                                                                                 *expected_sc_event_types,
                                                                                 *expected_imr_event_types)
          end
        end
      end

      context "days waiting filter" do
        context "less than number of days" do
          let(:filters) { { days_waiting: { number_of_days: 8, operator: "<" } } }

          it "should only return events for tasks that match the days waiting filter" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_hlr_event_types,
                                                                                 *expected_imr_event_types)
          end
        end

        context "greater than number of days" do
          let(:filters) { { days_waiting: { number_of_days: 15, operator: ">" } } }

          it "should only return events for tasks that match the days waiting filter" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_sc_event_types)
          end
        end

        context "equal to number of days" do
          let(:filters) { { days_waiting: { number_of_days: 5, operator: "=" } } }

          it "should only return events for tasks that match the days waiting filter", skip: "Flakey test" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_hlr_event_types)
          end
        end

        context "between number of days" do
          let(:filters) { { days_waiting: { number_of_days: 3, operator: "between", end_days: 6 } } }

          it "should only return events for tasks that match the days waiting filter" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_hlr_event_types)
          end
        end

        context "with no filter matches" do
          let(:filters) { { days_waiting: { number_of_days: 60, operator: ">", end_days: 6 } } }

          it "should return no events" do
            subject
            expect(service_instance.events).to eq([])
          end
        end
      end

      context "with personnel filter" do
        let(:filters) { { personnel: [update_user.css_id, sc_intake_user.css_id] } }

        it "should only return events with an event user that matches the user id(s) in the personnel filter" do
          subject
          expected_event_types = [
            :added_issue,
            :withdrew_issue,
            :claim_creation
          ]
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_event_types)
        end

        context "with no filter matches" do
          let(:filters) { { personnel: ["998"] } }

          it "should return no events" do
            subject
            expect(service_instance.events).to eq([])
          end
        end

        context "with personnel and claim type filter" do
          let(:filters) { { personnel: [update_user.css_id, sc_intake_user.css_id], claim_type: "HigherLevelReview" } }

          it "should only return events with an event user that matches the user id(s) in the personnel filter" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(:withdrew_issue)
          end
        end
      end

      context "with facilities filter" do
        let(:filters) { { facilities: [decision_user.station_id, update_user.station_id] } }

        it "should only return events with an event user that matches the station id(s) in the facilities filter" do
          subject
          expected_event_types = [
            :withdrew_issue,
            :completed_disposition,
            :completed_disposition,
            :added_issue,
            :claim_creation
          ]
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_event_types)
        end

        context "with no filter matches" do
          let(:filters) { { facilities: ["998"] } }

          it "should return no events" do
            subject
            expect(service_instance.events).to eq([])
          end
        end
      end

      context "with last_action_taken filter" do
        let(:filters) { { status_report_type: "last_action_taken" } }

        before do
          decision_issue.created_at = Time.zone.now + 1.day
          decision_issue.save

          sc_task.appeal.intake.completed_at = Time.zone.now + 1.day
          sc_task.appeal.intake.save
        end

        it "should only return the last event for each task" do
          subject
          expected_event_types = [
            :completed,
            :in_progress,
            :request_approved
          ]
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_event_types)
        end
      end

      context "with issue modification request task id" do
        let(:filters) { { task_id: hlr_task_with_imr.decision_review.tasks.ids[0] } }
        it "should only return the filtered events for the specific task ids" do
          subject
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_imr_event_types)
        end
      end

      context "with multiple filters for task id and event" do
        let(:filters) do
          { task_id: hlr_task_with_imr.decision_review.tasks.ids[0], events: [:added_issue, :claim_creation] }
        end

        it "should only return the filtered events for the specific task ids" do
          subject
          expect(service_instance.events.map(&:event_type)).to contain_exactly(:added_issue, :claim_creation)
        end
      end

      context "with multiple filters for task id and event" do
        let(:filters) do
          { task_id: hlr_task_with_imr.decision_review.tasks.ids[0], events: [:request_edited] }
        end

        it "should only return the filtered events for the specific task ids" do
          subject
          expect(service_instance.events.map(&:event_type)).to contain_exactly(:request_edited)
        end
      end

      context "with multiple filters for task id and event" do
        let(:filters) do
          { task_id: hlr_task_with_imr.decision_review.tasks.ids[0], events: [:request_approved] }
        end

        it "should only return the filtered events for the specific task ids" do
          subject
          expect(service_instance.events.map(&:event_type)).to contain_exactly(:request_approved)
        end
      end

      context "with multiple filters for task id and event" do
        let(:filters) do
          { task_id: hlr_task_with_imr.decision_review.tasks.ids[0], events: [:pending] }
        end

        it "should only return the filtered events for the specific task ids" do
          subject
          expect(service_instance.events.map(&:event_type)).to contain_exactly(:pending)
        end
      end
    end
  end
end
