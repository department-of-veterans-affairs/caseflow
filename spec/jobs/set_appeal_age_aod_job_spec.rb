# frozen_string_literal: true

describe SetAppealAgeAodJob, :postgres do
  include_context "Metrics Reports"

  # rubocop:disable Metrics/LineLength
  let(:success_msg) do
    "[INFO] SetAppealAgeAodJob completed after running for less than a minute."
  end
  # rubocop:enable Metrics/LineLength

  describe "#perform" do
    let(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }

    let(:age_aod_appeal) { create(:appeal, :with_schedule_hearing_tasks, :advanced_on_docket_due_to_age) }
    let(:motion_aod_appeal) { create(:appeal, :with_schedule_hearing_tasks, :advanced_on_docket_due_to_motion) }

    let(:inactive_age_aod_appeal) { create(:appeal, :advanced_on_docket_due_to_age) }
    let(:cancelled_age_aod_appeal) { create(:appeal, :advanced_on_docket_due_to_age, :cancelled) }

    before do
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
    end

    it "sets age_aod for only active appeals with a claimant that satisfies the age criteria" do
      expect(appeal.active?).to eq(true)
      expect(age_aod_appeal.active?).to eq(true)
      expect(motion_aod_appeal.active?).to eq(true)
      expect(inactive_age_aod_appeal.active?).to eq(false)
      expect(cancelled_age_aod_appeal.active?).to eq(false)

      described_class.perform_now
      expect(@slack_msg).to include(success_msg)

      # `age_aod` will be nil
      # `age_aod` being false means that it was once true (in the case where the claimant's DOB was updated)
      expect(appeal.reload.age_aod).not_to eq(true)
      expect(inactive_age_aod_appeal.reload.age_aod).not_to eq(true)

      expect(age_aod_appeal.reload.age_aod).to eq(true)
      expect(motion_aod_appeal.reload.age_aod).to eq(false)
    end

    context "when the entire job fails" do
      let(:error_msg) { "Some dummy error" }

      it "sends a message to Slack that includes the error" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        allow_any_instance_of(described_class).to receive(:non_aod_active_appeals).and_raise(error_msg)
        described_class.perform_now

        expected_msg = "#{described_class.name} failed after running for .*. Fatal error: #{error_msg}"
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end
  end
end
