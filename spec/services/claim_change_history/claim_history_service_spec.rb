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

  let(:expected_sc_event_types) do
    [
      :added_issue,
      :claim_creation,
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
        all_event_types = expected_hlr_event_types + expected_sc_event_types
        expect(events.count).to eq(14)
        expect(events.map(&:event_type)).to contain_exactly(*all_event_types)

        # Verify the issue data is correct for the completed_dispostion events
        disposition_events = events.select { |event| event.event_type == :completed_disposition }
        disposition_issue_types = ["Caregiver | Other", "Camp Lejune Family Member"]
        disposition_issue_descriptions = ["VHA - Caregiver ", "Camp Lejune description"]
        disposition_user_names = ["Gaius Baelsar", "Gaius Baelsar"]
        disposition_values = %w[Granted denied]
        disposition_dates = [5.days.ago.to_date.to_s] * 2

        expect(disposition_events.map(&:issue_type)).to contain_exactly(*disposition_issue_types)
        expect(disposition_events.map(&:issue_description)).to contain_exactly(*disposition_issue_descriptions)
        expect(disposition_events.map(&:event_user_name)).to contain_exactly(*disposition_user_names)
        expect(disposition_events.map(&:disposition)).to contain_exactly(*disposition_values)
        expect(disposition_events.map(&:disposition_date)).to contain_exactly(*disposition_dates)

        # Verify the issue data is correct for all the add issue events
        added_issue_types = [*disposition_issue_types, "CHAMPVA", "Beneficiary Travel"]
        added_issue_descriptions = [*disposition_issue_descriptions, "Withdrew CHAMPVA", "VHA issue description "]
        added_issue_user_names = ["Lauren Roth", "Lauren Roth", "Lauren Roth", "Eleanor Reynolds"]
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
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_hlr_event_types)
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
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_sc_event_types)
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
            expect(service_instance.events.count).to eq(14)
          end
        end
      end

      context "with issue_types filter" do
        let(:filters) { { issue_types: ["Caregiver | Other"] } }

        it "should only return events for the tasks that match the issue types filter" do
          subject
          expected_event_types = [
            :added_issue,
            :completed_disposition
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
              :withdrew_issue
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
              *expected_sc_event_types
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
              *expected_sc_event_types
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
              *expected_sc_event_types
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
                                                                                 *expected_sc_event_types)
          end
        end
      end

      context "days waiting filter" do
        context "less than number of days" do
          let(:filters) { { days_waiting: { number_of_days: 8, operator: "<" } } }

          it "should only return events for tasks that match the days waiting filter" do
            subject
            expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_hlr_event_types)
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
            :in_progress
          ]
          expect(service_instance.events.map(&:event_type)).to contain_exactly(*expected_event_types)
        end
      end
    end
  end
end
