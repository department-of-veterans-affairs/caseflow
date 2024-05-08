# frozen_string_literal: true

require_relative "../../../app/services/claim_change_history/change_history_reporter.rb"
require_relative "../../../app/services/claim_change_history/claim_history_event.rb"

describe ChangeHistoryReporter do
  let(:events) { [] }
  let(:tasks_url) { "" }
  let(:filters) { {} }
  let(:column_headers) { ChangeHistoryReporter.const_get(:CHANGE_HISTORY_CSV_COLUMNS) }
  let(:reporter_object) { ChangeHistoryReporter.new(events, tasks_url, filters) }

  describe ".formatted_event_filters" do
    subject { reporter_object.formatted_event_filters }

    it "returns an empty array for no filters" do
      expect(subject).to eq([])
    end

    context "with filter values" do
      let(:filters) do
        {
          events: [:completed, :cancelled],
          task_status: [:testing1, :testing2],
          status_report_type: nil,
          claim_type: %w[HigherLevelReview SupplementalClaim],
          personnel: nil,
          dispositions: nil,
          issue_types: nil,
          facilities: nil,
          timing: { range: nil },
          days_waiting: { operator: ">", num_days: 10 }
        }
      end

      it "returns a readable array built from the filter values" do
        expected_formatted_filter = [
          "events: [completed, cancelled]",
          "task_status: [testing1, testing2]",
          "claim_type: [HigherLevelReview, SupplementalClaim]",
          "timing: [range: None]",
          "days_waiting: [operator: >, num_days: 10]"
        ]
        expect(subject).to eq(expected_formatted_filter)
      end
    end
  end

  describe ".as_csv" do
    subject { reporter_object.as_csv }

    it "returns a csv string with the column headers, filters, and no events" do
      rows = CSV.parse(subject)
      expect(rows.count).to eq(2)
      expect(rows[0]).to eq([])
      expect(rows[1]).to eq(column_headers)
    end

    context "has events" do
      let(:claimant_name) { "Mason Rodriguez" }
      let(:tasks_url) { "/decision_reviews/vha/tasks/" }
      let(:added_issue_event) do
        c = ClaimHistoryEvent.new(:added_issue, {})
        c.instance_variable_set(:@event_date, Time.zone.now.iso8601)
        c.instance_variable_set(:@event_user_name, "Elena Thompson")
        c.instance_variable_set(:@claimant_name, claimant_name)
        c.instance_variable_set(:@days_waiting, "20")
        c.instance_variable_set(:@benefit_type, "vha")
        c.instance_variable_set(:@issue_type, "CHAMPVA")
        c.instance_variable_set(:@issue_description, "CHAMPVA issue description")
        c.instance_variable_set(:@decision_date, 10.days.ago.iso8601)
        c.instance_variable_set(:@claim_type, "HigherLevelReview")
        c.instance_variable_set(:@task_status, "assigned")
        c.instance_variable_set(:@veteran_file_number, "242080004")
        c.instance_variable_set(:@user_facility, "101")
        c.instance_variable_set(:@task_id, 999)
        c
      end
      let(:claim_creation_event) do
        new_event = added_issue_event.clone
        new_event.instance_variable_set(:@event_type, :claim_creation)
        new_event.instance_variable_set(:@event_user_name, "System")
        new_event.instance_variable_set(:@user_facility, nil)
        new_event
      end
      let(:in_progress_status_event) do
        new_event = claim_creation_event.clone
        new_event.instance_variable_set(:@event_type, :in_progress)
        new_event
      end
      let(:cancelled_status_event) do
        new_event = in_progress_status_event.clone
        new_event.instance_variable_set(:@event_type, :cancelled)
        new_event.instance_variable_set(:@task_status, "cancelled")
        new_event
      end
      let(:completed_status_event) do
        new_event = in_progress_status_event.clone
        new_event.instance_variable_set(:@event_type, :completed)
        new_event.instance_variable_set(:@task_status, "completed")
        new_event.instance_variable_set(:@claim_type, "SupplementalClaim")
        new_event
      end
      let(:incomplete_status_event) do
        new_event = in_progress_status_event.clone
        new_event.instance_variable_set(:@event_type, :incomplete)
        new_event.instance_variable_set(:@task_status, "on_hold")
        new_event.instance_variable_set(:@claim_type, "SupplementalClaim")
        new_event
      end
      let(:added_issue_without_decision_date_event) do
        new_event = added_issue_event.clone
        new_event.instance_variable_set(:@event_type, :added_issue_without_decision_date)
        new_event.instance_variable_set(:@task_status, "on_hold")
        new_event.instance_variable_set(:@claim_type, "SupplementalClaim")
        new_event.instance_variable_set(:@decision_date, nil)
        new_event
      end
      let(:completed_disposition_event) do
        new_event = added_issue_event.clone
        new_event.instance_variable_set(:@event_type, :completed_disposition)
        new_event.instance_variable_set(:@task_status, "completed")
        new_event.instance_variable_set(:@disposition, "Granted")
        new_event.instance_variable_set(:@decision_description, "Decision for CHAMPVA issue")
        new_event.instance_variable_set(:@disposition_date, 4.days.ago.iso8601)
        new_event.instance_variable_set(:@user_facility, "200")
        new_event
      end
      let(:added_decision_date_event) do
        new_event = completed_disposition_event.clone
        new_event.instance_variable_set(:@event_type, :added_decision_date)
        new_event.instance_variable_set(:@task_status, "assigned")
        new_event.instance_variable_set(:@task_id, 900)
        new_event
      end
      let(:removed_issue_event) do
        new_event = added_decision_date_event.clone
        new_event.instance_variable_set(:@event_type, :removed_issue)
        new_event.instance_variable_set(:@task_status, "cancelled")
        new_event
      end
      let(:withdrew_issue_event) do
        new_event = removed_issue_event.clone
        new_event.instance_variable_set(:@event_type, :withdrew_issue)
        new_event.instance_variable_set(:@task_status, "cancelled")
        new_event
      end

      let(:events) do
        [
          added_issue_event,
          claim_creation_event,
          in_progress_status_event,
          cancelled_status_event,
          completed_status_event,
          incomplete_status_event,
          added_issue_without_decision_date_event,
          completed_disposition_event,
          added_decision_date_event,
          removed_issue_event,
          withdrew_issue_event
        ]
      end

      let(:added_issue_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/999",
          "in progress",
          "20",
          "Higher-Level Review",
          "VACO (101)",
          "E. Thompson",
          added_issue_event.readable_event_date,
          "Added issue",
          "CHAMPVA",
          "CHAMPVA issue description",
          added_issue_event.readable_decision_date,
          nil
        ]
      end

      let(:claim_creation_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/999",
          "in progress",
          "20",
          "Higher-Level Review",
          "",
          "System",
          claim_creation_event.readable_event_date,
          "Claim created",
          nil,
          "Claim created.",
          nil
        ]
      end

      let(:in_progress_status_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/999",
          "in progress",
          "20",
          "Higher-Level Review",
          "",
          "System",
          in_progress_status_event.readable_event_date,
          "Claim status - In progress",
          nil,
          "Claim can be processed.",
          nil
        ]
      end

      let(:cancelled_status_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/999",
          "cancelled",
          "20",
          "Higher-Level Review",
          "",
          "System",
          cancelled_status_event.readable_event_date,
          "Claim closed",
          nil,
          "Claim closed.",
          nil
        ]
      end
      let(:completed_status_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/999",
          "completed",
          "20",
          "Supplemental Claim",
          "",
          "System",
          completed_status_event.readable_event_date,
          "Claim closed",
          nil,
          "Claim closed.",
          nil
        ]
      end
      let(:incomplete_status_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/999",
          "incomplete",
          "20",
          "Supplemental Claim",
          "",
          "System",
          incomplete_status_event.readable_event_date,
          "Claim status - Incomplete",
          nil,
          "Claim cannot be processed until decision date is entered.",
          nil
        ]
      end
      let(:added_issue_without_decision_date_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/999",
          "incomplete",
          "20",
          "Supplemental Claim",
          "VACO (101)",
          "E. Thompson",
          added_issue_without_decision_date_event.readable_event_date,
          "Added issue - No decision date",
          "CHAMPVA",
          "CHAMPVA issue description",
          added_issue_without_decision_date_event.readable_decision_date,
          nil
        ]
      end
      let(:completed_disposition_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/999",
          "completed",
          "20",
          "Higher-Level Review",
          "Austin AAC (200)",
          "E. Thompson",
          completed_disposition_event.readable_event_date,
          "Completed disposition",
          "CHAMPVA",
          "CHAMPVA issue description",
          completed_disposition_event.readable_decision_date,
          "Granted",
          "Decision for CHAMPVA issue",
          completed_disposition_event.readable_disposition_date
        ]
      end
      let(:added_decision_date_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/900",
          "in progress",
          "20",
          "Higher-Level Review",
          "Austin AAC (200)",
          "E. Thompson",
          added_decision_date_event.readable_event_date,
          "Added decision date",
          "CHAMPVA",
          "CHAMPVA issue description",
          added_decision_date_event.readable_decision_date,
          nil
        ]
      end
      let(:removed_issue_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/900",
          "cancelled",
          "20",
          "Higher-Level Review",
          "Austin AAC (200)",
          "E. Thompson",
          removed_issue_event.readable_event_date,
          "Removed issue",
          "CHAMPVA",
          "CHAMPVA issue description",
          removed_issue_event.readable_decision_date,
          nil
        ]
      end
      let(:withdrew_issue_event_row) do
        [
          "242080004",
          "Mason Rodriguez",
          "/decision_reviews/vha/tasks/900",
          "cancelled",
          "20",
          "Higher-Level Review",
          "Austin AAC (200)",
          "E. Thompson",
          withdrew_issue_event.readable_event_date,
          "Withdrew issue",
          "CHAMPVA",
          "CHAMPVA issue description",
          withdrew_issue_event.readable_decision_date,
          nil
        ]
      end

      it "returns a csv string with the column headers, filters, and event rows" do
        rows = CSV.parse(subject)
        expect(rows.count).to eq(2 + events.length)
        expect(rows[0]).to eq([])
        expect(rows[1]).to eq(column_headers)
        expect(rows[2]).to eq(added_issue_event_row)
        expect(rows[3]).to eq(claim_creation_event_row)
        expect(rows[4]).to eq(in_progress_status_event_row)
        expect(rows[5]).to eq(cancelled_status_event_row)
        expect(rows[6]).to eq(completed_status_event_row)
        expect(rows[7]).to eq(incomplete_status_event_row)
        expect(rows[8]).to eq(added_issue_without_decision_date_event_row)
        expect(rows[9]).to eq(completed_disposition_event_row)
        expect(rows[10]).to eq(added_decision_date_event_row)
        expect(rows[11]).to eq(removed_issue_event_row)
        expect(rows[12]).to eq(withdrew_issue_event_row)
      end
    end
  end
end
