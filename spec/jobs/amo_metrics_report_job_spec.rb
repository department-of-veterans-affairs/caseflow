# frozen_string_literal: true

describe AMOMetricsReportJob, :postgres do
  include_context "Metrics Reports"

  # rubocop:disable Metrics/LineLength
  let(:report) do
    "AMO metrics report 2019-03-01 to 2019-03-29\nSupplemental Claims 1 established, median 24:00:00 average 24:00:00\nSupplemental Claims newly stuck: 0\nSupplemental Claims total stuck: 0\nHigher Level Reviews 1 established, median 00:00:00 average 00:00:00\nHigher Level Reviews newly stuck: 0\nHigher Level Reviews total stuck: 0\ntype,total,in_progress,cancelled,processed,established_within_seven_days,established_within_seven_days_percent,median,avg,max,min\nsupplemental_claims,1,0,0,1,1,100.0,24:00:00,24:00:00,24:00:00,24:00:00\nhigher_level_reviews,1,0,1,0,0,0.0,00:00:00,00:00:00,00:00:00,00:00:00\nrequest_issues_updates,1,0,0,1,1,100.0,24:00:00,24:00:00,24:00:00,24:00:00\n"
  end
  # rubocop:enable Metrics/LineLength

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
