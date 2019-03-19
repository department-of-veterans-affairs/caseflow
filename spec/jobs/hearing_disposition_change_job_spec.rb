# frozen_string_literal: true

require "rails_helper"

describe HearingDispositionChangeJob do
  describe ".log_info" do
    let(:start_time) { 5.minutes.ago }
    let(:task_count_for) { {} }
    let(:error_count) { 0 }
    let(:hearing_ids) { [] }
    let(:error) { nil }

    context "when the job runs successfully" do
      it "logs and sends the correct message to slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        expect(Rails.logger).to receive(:info).exactly(2).times

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob completed after running for .*." \
          " Encountered errors for #{error_count} hearings."
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end

    context "when there is are elements in the input task_count_for hash" do
      let(:task_count_for) { { first_key: 0, second_key: 13 } }

      it "includes a sentence in the output message for each element of the hash" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob completed after running for .*." \
          " Processed 0 First key hearings." \
          " Processed 13 Second key hearings." \
          " Encountered errors for #{error_count} hearings."
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end

    context "when the job encounters a fatal error" do
      let(:err_msg) { "Example error text" }
      # Throw and then catch the error so it has a stack trace.
      let(:error) do
        fail StandardError, err_msg
      rescue StandardError => e
        e
      end

      it "logs an error message and sends the correct message to slack" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        expect(Rails.logger).to receive(:info).exactly(3).times

        HearingDispositionChangeJob.new.log_info(start_time, task_count_for, error_count, hearing_ids, error)

        expected_msg = "HearingDispositionChangeJob failed after running for .*." \
          " Encountered errors for #{error_count} hearings. Fatal error: #{err_msg}"
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end
  end
end
