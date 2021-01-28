# frozen_string_literal: true

describe SetAppealAgeAodJob, :postgres do
  include_context "Metrics Reports"

  describe "#perform" do
    let(:non_aod_appeal) { create(:appeal, :with_schedule_hearing_tasks) }

    # appeal with wrong date-of-birth causing AOD; it is fixed in the before block
    let(:age_aod_appeal_wrong_dob) { create(:appeal, :with_schedule_hearing_tasks, :advanced_on_docket_due_to_age) }

    let(:age_aod_appeal) { create(:appeal, :with_schedule_hearing_tasks, :advanced_on_docket_due_to_age) }
    let(:motion_aod_appeal) { create(:appeal, :with_schedule_hearing_tasks, :advanced_on_docket_due_to_motion) }

    let(:inactive_age_aod_appeal) { create(:appeal, :advanced_on_docket_due_to_age) }
    let(:cancelled_age_aod_appeal) { create(:appeal, :advanced_on_docket_due_to_age, :cancelled) }

    before do
      allow_any_instance_of(SlackService).to receive(:send_notification) do |_, msg, title|
        @slack_msg = msg
        @slack_title = title
      end

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

      inactive_age_aod_appeal__aod_based_on_age = inactive_age_aod_appeal.aod_based_on_age
      described_class.perform_now
      expect(@slack_title).to include("[INFO] SetAppealAgeAodJob completed after running for less than a minute.")

      # `aod_based_on_age` will be nil or the same as it was before the job
      # `aod_based_on_age` being false means that it was once true (in the case where the claimant's DOB was updated)
      expect(non_aod_appeal.reload.aod_based_on_age).not_to eq(true)
      expect(inactive_age_aod_appeal.reload.aod_based_on_age).to eq(inactive_age_aod_appeal__aod_based_on_age)

      expect(age_aod_appeal.reload.aod_based_on_age).to eq(true)
      expect(motion_aod_appeal.reload.aod_based_on_age).not_to eq(true)

      expect(age_aod_appeal_wrong_dob.reload.aod_based_on_age).to eq(false)
    end

    context "when the entire job fails" do
      let(:error_msg) { "Some dummy error" }

      it "sends a message to Slack that includes the error" do
        allow_any_instance_of(SlackService).to receive(:send_notification) do |_, msg, title|
          @slack_msg = msg
          @slack_title = title
        end

        allow_any_instance_of(described_class).to receive(:appeals_to_set_age_based_aod).and_raise(error_msg)
        described_class.perform_now

        expect(@slack_title).to match(/#{described_class.name} failed after running for .*. Fatal error: #{error_msg}/)
      end
    end
  end
end
