# frozen_string_literal: true

describe QuarterlyMetricsReportJob, :postgres do
  include_context "Metrics Reports"

  # rubocop:disable Layout/LineLength
  let(:report) do
    [
      "Quarterly report 2018-12-01 to 2019-02-28",
      "Percentage of all cases certified with Caseflow: 100.0%",
      "Appeals established within 7 days: 1 (100%)",
      "Supplemental Claims within 7 days: 1 (25.0%)",
      "Higher Level Reviews within 7 days: 2 (50.0%)",

      "Hearings Show Rate: 66.67%",
      "Percent of non-denial decisions with an EP created within 7 days: 40.0%",
      "Mean time to recovery: See the 'Quarterly OIT Report' tab of the 'Caseflow Incident Stats' Google Sheet (https://docs.google.com/spreadsheets/d/1OAx_eRhwTaEM9aMx7eGg4KMR3Jgx5wYvsVBypHsZq5Q/edit#gid=593310513)",

      "type,total,in_progress,cancelled,processed,established_within_seven_days,established_within_seven_days_percent,median,avg,max,min",
      "supplemental_claims,4,1,1,2,1,25.0,373:30:00,373:30:00,743:00:00,04:00:00",
      "higher_level_reviews,4,1,0,3,2,50.0,04:00:00,249:20:00,743:00:00,01:00:00",
      "request_issues_updates,3,0,1,2,1,33.33,384:00:00,384:00:00,767:00:00,01:00:00",
      "" # We end the body of the message with a newline character.
    ].join("\n")
  end
  # rubocop:enable Layout/LineLength

  describe "#perform" do
    before do
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
    end

    it "sends message" do
      described_class.perform_now

      expect(@slack_msg).to eq(report)
    end
  end
end
