# frozen_string_literal: true

describe FetchAllActiveLegacyAppealsJob, type: :job do
  include ActiveJob::TestHelper


  subject { FetchAllActiveLegacyAppealsJob.new }

  describe "#perform" do
    it "sets the USER and Perfoms the Job" do
      expect(RequestStore[:current_user]).to eq(nil)
      subject.perform
      expect(RequestStore[:current_user]).to eq(User.system_user)
    end
    it "calls #find_and_create_appeal_state_for_active_legacy_appeals" do
      expect(subject).to receive(:find_and_create_appeal_state_for_active_legacy_appeals)
      subject.perform
    end
  end

  describe "#find_and_create_appeal_state_for_active_legacy_appeals" do
    context "when there are only CLOSED Legacy Appeals in the database" do
      let!(:closed_legacy_appeals) do
        [
          create(:legacy_appeal, :with_completed_root_task, vacols_id: "1"),
          create(:legacy_appeal, :with_completed_root_task, vacols_id: "2"),
          create(:legacy_appeal, :with_completed_root_task, vacols_id: "3"),
          create(:legacy_appeal, :with_completed_root_task, vacols_id: "4"),
          create(:legacy_appeal, :with_completed_root_task, vacols_id: "5")
        ]
      end
      it "no records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.count).to eq(0)
      end
    end

    context "when there are only OPEN Legacy Appeals in the database" do
      let!(:open_legacy_appeals) do
        [
          create(:legacy_appeal, :with_root_task, vacols_id: "10"),
          create(:legacy_appeal, :with_root_task, vacols_id: "20"),
          create(:legacy_appeal, :with_root_task, vacols_id: "30"),
          create(:legacy_appeal, :with_root_task, vacols_id: "40"),
          create(:legacy_appeal, :with_root_task, vacols_id: "50")
        ]
      end
      it "5 records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.count).to eq(5)
      end
    end

    context "when there are both OPEN & CLOSED Legacy Appeals in the database" do
      let!(:open_legacy_appeals) do
        [
          create(:legacy_appeal, :with_root_task, vacols_id: "100"),
          create(:legacy_appeal, :with_root_task, vacols_id: "200"),
          create(:legacy_appeal, :with_root_task, vacols_id: "300"),
          create(:legacy_appeal, :with_root_task, vacols_id: "400"),
          create(:legacy_appeal, :with_root_task, vacols_id: "500")
        ]
      end
      let!(:closed_legacy_appeals) do
        [
          create(:legacy_appeal, :with_completed_root_task, vacols_id: "1000"),
          create(:legacy_appeal, :with_completed_root_task, vacols_id: "2000"),
          create(:legacy_appeal, :with_completed_root_task, vacols_id: "3000"),
          create(:legacy_appeal, :with_completed_root_task, vacols_id: "4000"),
          create(:legacy_appeal, :with_completed_root_task, vacols_id: "5000")
        ]
      end
      it "only OPEN Legacy Appeal records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.map(&:appeal_id)).to eq(open_legacy_appeals.map(&:id))
        expect(AppealState.all.count).to eq(5)
      end
    end
  end

  describe "#add_record_to_appeal_states_table" do
    let!(:appeal) { create(:appeal, :active) }
    let(:error) { StandardError }
    context "When an error is raised" do
      it "will log error and continue" do
        allow(Rails.logger).to receive(:error)
        allow(subject).to receive(:map_appeal_ihp_state).with(appeal).and_raise(error)
        subject.send(:add_record_to_appeal_states_table, appeal)
        expect(Rails.logger).to have_received(:error).with(
          "\e[31m#{appeal&.class} ID #{appeal&.id} was unable to create an appeal_states record "\
          "because of #{error}\e[0m"
        )
      end
    end
  end

  describe "map appeal state with hearing scheduled" do
    let(:legacy_appeal) do
      create(:legacy_appeal, :with_veteran,
             vacols_case: create(:case, :aod))
    end
    context "appeals with hearings scheduled tasks" do
      let(:legacy_hearing) { create(:legacy_hearing, appeal: legacy_appeal) }

      it "hearings with nil disposition should map the hearing scheduled appeal state to true" do
        hearing.update(disposition: nil)
        expect(subject.send(:map_appeal_hearing_scheduled_state, legacy_appeal)).to eq(hearing_scheduled: true)
      end

      it "no hearings with nil disposition should map the hearing scheduled appeal state to false" do
        hearing.update(disposition: Constants.HEARING_DISPOSITION_TYPES.held)
        expect(subject.send(:map_appeal_hearing_scheduled_state, legacy_appeal)).to eq(hearing_scheduled: false)
      end
    end

    context "appeals hearings with multiple hearings scheduled" do
      let(:old_hearing) { create(:legacy_hearing, appeal: legacy_appeal) }
      let(:new_hearing) { create(:legacy_hearing, appeal: legacy_appeal) }
      it "should still map appeal state to true if most recent hearing has nil disposition" do
        old_hearing.update(disposition: Constants.HEARING_DISPOSITION_TYPES.cancelled)
        new_hearing.update(disposition: nil)
        expect(subject.send(:map_appeal_hearing_scheduled_state, legacy_appeal)).to eq(hearing_scheduled: true)
      end

      it "should not map appeal state to true if none of the hearings habe nil dispsotion" do
        old_hearing.update(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
        new_hearing.update(disposition: Constants.HEARING_DISPOSITION_TYPES.held)
        expect(subject.send(:map_appeal_hearing_scheduled_state, legacy_appeal)).to eq(hearing_scheduled: false)
      end
    end
  end
end
