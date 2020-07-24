# frozen_string_literal: true

describe SetAppealAgeAodJob, :postgres do
  include_context "Metrics Reports"

  # rubocop:disable Metrics/LineLength
  let(:report) do
    "[INFO] SetAppealAgeAodJob completed after running for less than a minute."
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
