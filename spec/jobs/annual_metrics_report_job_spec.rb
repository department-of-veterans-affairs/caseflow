# frozen_string_literal: true

describe AnnualMetricsReportJob, :postgres do
  include_context "Metrics Reports"

  # rubocop:disable Layout/LineLength
  let(:report) do
    [
      "Annual report 2018-03-01 to 2019-02-28",
      "Percentage of all cases certified with Caseflow: 100.0%",
      "Appeals established within 7 days: 1 (100%)",
      "Supplemental Claims within 7 days: 1 (20.0%)",
      "Higher Level Reviews within 7 days: 2 (40.0%)",

      "Reader Adoption Rate: 80.0%",

      "type,total,in_progress,cancelled,processed,established_within_seven_days,established_within_seven_days_percent,median,avg,max,min",
      "supplemental_claims,5,1,1,3,1,20.0,743:00:00,1850:40:00,4805:00:00,04:00:00",
      "higher_level_reviews,5,1,0,4,2,40.0,373:30:00,1387:15:00,4801:00:00,01:00:00",
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
