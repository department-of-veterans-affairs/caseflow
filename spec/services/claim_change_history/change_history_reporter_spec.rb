# frozen_string_literal: true

require_relative "../../../app/services/claim_change_history/change_history_reporter.rb"

describe ChangeHistoryReporter do
  let(:events) { [] }
  let(:tasks_url) { "" }
  let(:filters) { {} }
  let(:column_headers) { ChangeHistoryReporter.const_get(:CHANGE_HISTORY_CSV_COLUMNS) }
  let(:reporter_object) { ChangeHistoryReporter.new(events, tasks_url, filters) }

  describe ".event_filter_headers" do
    subject { reporter_object.event_filter_headers }

    it "returns an empty array for no filters" do
      expect(subject).to eq([])
    end

    context "with filter values" do
      let(:filters) do
        {
          "report_type" => "event_type_action",
          "timing" => {
            "range" => "after",
            "start_date" => Time.zone.now
          },
          "days_waiting" => {
            "comparison_operator" => "moreThan",
            "value_one" => "6"
          },
          "personnel" => {
            "0" => "CAREGIVERADMIN",
            "1" => "VHAPOADMIN",
            "2" => "THOMAW2VACO"
          },
          "decision_review_type" => {
            "0" => "HigherLevelReview",
            "1" => "SupplementalClaim"
          }
        }
      end

      it "returns a readable array built from the filter values" do
        expect(subject).to eq(filters.to_a.flatten)
      end
    end
  end

  describe ".as_csv" do
    subject { reporter_object.as_csv }

    let(:column_header_string) do
      "\nVeteran File Number,Claimant,Task URL,Current Claim Status,Days Waiting," \
      "Claim Type,Facility,Edit U...e Type,Issue Description,Prior Decision Date," \
      "Disposition,Disposition Description,Disposition Date\n"
    end

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
