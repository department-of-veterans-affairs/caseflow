# frozen_string_literal: true

describe FetchAllActiveAmaAppealsJob, type: :job do
  include ActiveJob::TestHelper

  subject { FetchAllActiveAmaAppealsJob.new }

  describe "#perform" do
    it "sets the USER and Perfoms the Job" do
      expect(RequestStore[:current_user]).to eq(nil)
      subject.perform
      expect(RequestStore[:current_user]).to eq(User.system_user)
    end
    it "calls #find_and_create_appeal_state_for_active_ama_appeals" do
      expect(subject).to receive(:find_and_create_appeal_state_for_active_ama_appeals)
      subject.perform
    end
  end

  describe "#find_and_create_appeal_state_for_active_ama_appeals" do
    context "when there are only CLOSED AMA Appeals in the database" do
      let!(:closed_ama_appeals) do
        Array.new(5) { create(:appeal, :with_completed_root_task) }
      end
      it "no records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.count).to eq(0)
      end
    end

    context "when there are only OPEN AMA Appeals in the database" do
      let!(:open_ama_appeals) do
        Array.new(5) { create(:appeal, :active) }
      end
      it "5 records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.count).to eq(5)
      end
    end

    context "when there are both OPEN & CLOSED AMA Appeals in the database" do
      let!(:open_ama_appeals) do
        Array.new(5) { create(:appeal, :active) }
      end
      let!(:closed_ama_appeals) do
        Array.new(5) { create(:appeal, :with_completed_root_task) }
      end
      it "only OPEN Legacy Appeal records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.map(&:appeal_id)).to eq(open_ama_appeals.map(&:id))
        expect(AppealState.all.count).to eq(5)
      end
    end
  end

  describe "#add_record_to_appeal_states_table" do
    let!(:legacy_appeal) { create(:legacy_appeal) }
    let(:error) { StandardError }
    context "When an error is raised" do
      it "will log error and continue" do
        allow(Rails.logger).to receive(:error)
        allow(subject).to receive(:map_appeal_ihp_state).with(legacy_appeal).and_raise(error)
        subject.send(:add_record_to_appeal_states_table, legacy_appeal)
        expect(Rails.logger).to have_received(:error).with(
          "\e[31m#{legacy_appeal&.class} ID #{legacy_appeal&.id} was unable to create an appeal_states record "\
          "because of #{error}\e[0m"
        )
      end
    end
  end

  describe "map appeal state with hearing scheduled" do
    let(:ama_appeal) { create(:appeal) }
    context "appeals with hearings scheduled tasks" do
      let(:hearing) { create(:hearing, appeal: ama_appeal) }

      it "hearings with nil disposition should map the hearing scheduled appeal state to true" do
        hearing.update(disposition: nil)
        expect(subject.send(:map_appeal_hearing_scheduled_state, ama_appeal)).to eq(hearing_scheduled: true)
      end

      it "no hearings with nil disposition should map the hearing scheduled appeal state to false" do
        hearing.update(disposition: Constants.HEARING_DISPOSITION_TYPES.held)
        expect(subject.send(:map_appeal_hearing_scheduled_state, ama_appeal)).to eq(hearing_scheduled: false)
      end
    end

    context "appeals hearings with multiple hearings scheduled" do
      let(:old_hearing) { create(:hearing, appeal: ama_appeal) }
      let(:new_hearing) { create(:hearing, appeal: ama_appeal) }
      it "should still map appeal state to true if most recent hearing has nil disposition" do
        old_hearing.update(disposition: Constants.HEARING_DISPOSITION_TYPES.cancelled)
        new_hearing.update(disposition: nil)
        expect(subject.send(:map_appeal_hearing_scheduled_state, ama_appeal)).to eq(hearing_scheduled: true)
      end

      it "should not map appeal state to true if none of the hearings habe nil disposition" do
        old_hearing.update(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
        new_hearing.update(disposition: Constants.HEARING_DISPOSITION_TYPES.held)
        expect(subject.send(:map_appeal_hearing_scheduled_state, ama_appeal)).to eq(hearing_scheduled: false)
      end
    end

    context "appeals without any hearing scheduled tasks" do
      it "should not map appeal state to true if there arent any hearings" do
        subject.send(:map_appeal_hearing_scheduled_state, ama_appeal)
        expect(subject.send(:map_appeal_hearing_scheduled_state, ama_appeal)).to eq(hearing_scheduled: false)
      end
    end
  end
end
