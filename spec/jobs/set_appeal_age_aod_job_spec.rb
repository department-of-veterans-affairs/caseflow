# frozen_string_literal: true

describe SetAppealAgeAodJob, :postgres do
  include_context "Metrics Reports"

  # rubocop:disable Metrics/LineLength
  let(:success_msg) do
    "[INFO] SetAppealAgeAodJob completed after running for less than a minute."
  end
  # rubocop:enable Metrics/LineLength

  describe "#perform" do
    let(:non_aod_appeal) { create(:appeal, :with_schedule_hearing_tasks) }

    # appeal with wrong date-of-birth causing AOD; it is fixed in the before block
    let(:age_aod_appeal_wrong_dob) { create(:appeal, :with_schedule_hearing_tasks, :advanced_on_docket_due_to_age) }

    let(:age_aod_appeal) { create(:appeal, :with_schedule_hearing_tasks, :advanced_on_docket_due_to_age) }
    let(:motion_aod_appeal) { create(:appeal, :with_schedule_hearing_tasks, :advanced_on_docket_due_to_motion) }

    let(:inactive_age_aod_appeal) { create(:appeal, :advanced_on_docket_due_to_age) }
    let(:cancelled_age_aod_appeal) { create(:appeal, :advanced_on_docket_due_to_age, :cancelled) }

    before do
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }

      age_aod_appeal_wrong_dob.update(aod_based_on_age: true)
      # simulate date-of-birth being corrected
      age_aod_appeal_wrong_dob.claimant.person.update(date_of_birth: 50.years.ago)
    end

    it "sets aod_based_on_age for only active appeals with a claimant that satisfies the age criteria" do
      expect(non_aod_appeal.active?).to eq(true)
      expect(age_aod_appeal.active?).to eq(true)
      expect(motion_aod_appeal.active?).to eq(true)
      expect(inactive_age_aod_appeal.active?).to eq(false)
      expect(cancelled_age_aod_appeal.active?).to eq(false)

      expect(age_aod_appeal_wrong_dob.aod_based_on_age).to eq(true)

      described_class.perform_now
      expect(@slack_msg).to include(success_msg)

      # `aod_based_on_age` will be nil
      # `aod_based_on_age` being false means that it was once true (in the case where the claimant's DOB was updated)
      expect(non_aod_appeal.reload.aod_based_on_age).not_to eq(true)
      expect(inactive_age_aod_appeal.reload.aod_based_on_age).not_to eq(true)

      expect(age_aod_appeal.reload.aod_based_on_age).to eq(true)
      expect(motion_aod_appeal.reload.aod_based_on_age).not_to eq(true)

      expect(age_aod_appeal_wrong_dob.reload.aod_based_on_age).to eq(false)
    end

    context "when the entire job fails" do
      let(:error_msg) { "Some dummy error" }

      it "sends a message to Slack that includes the error" do
        slack_msg = ""
        allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

        allow_any_instance_of(described_class).to receive(:appeals_to_set_age_based_aod).and_raise(error_msg)
        described_class.perform_now

        expected_msg = "#{described_class.name} failed after running for .*. Fatal error: #{error_msg}"
        expect(slack_msg).to match(/#{expected_msg}/)
      end
    end
  end
end
