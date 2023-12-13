# frozen_string_literal: true

require_relative "../../../app/services/claim_change_history/change_history_reporter.rb"

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
          "timing: {:range=>nil}",
          "days_waiting: {:operator=>\">\", :num_days=>10}"
        ]
        expect(subject).to eq(expected_formatted_filter)
      end
    end
  end

  describe ".as_csv" do
    subject { reporter_object.as_csv }

    it "returns a csv string with the column headers and the filters with no events" do
      rows = CSV.parse(subject)
      expect(rows.count).to eq(2)
      expect(rows[0]).to eq([])
      expect(rows[1]).to eq(column_headers)
    end

    context "it does things when it has events" do
      # TODO: Add some specific tests here for output
    end
  end
end
