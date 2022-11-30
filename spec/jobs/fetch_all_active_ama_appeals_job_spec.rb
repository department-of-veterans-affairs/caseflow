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

    context "when there are only CANCELLED AMA Appeals in the database" do
      let!(:cancelled_ama_appeals) do
        Array.new(5) { create(:appeal, :with_cancelled_root_task) }
      end
      it "5 records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.count).to eq(cancelled_ama_appeals.count)
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

  describe "#map_appeal_ihp_state" do
    context "when there is an active AMA Appeal with an active InformalHearingPresentationTask" do
      let!(:open_ama_appeal_with_ihp_pending) { create(:appeal, :active, :with_ihp_task) }
      it "a single record will be inserted into the Appeal States table" do
        subject.perform
        expect(
          AppealState.find_by(
            appeal_id: open_ama_appeal_with_ihp_pending.id,
            appeal_type: open_ama_appeal_with_ihp_pending.class.to_s
          ).appeal_id
        ).to eq(open_ama_appeal_with_ihp_pending.id)
        expect(AppealState.all.count).to eq(1)
      end

      it "the #{"vso_ihp_pending"} column will be set to TRUE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_ama_appeal_with_ihp_pending.id).vso_ihp_pending).to eq(true)
      end

      it "the #{"vso_ihp_complete"} column will be set to FALSE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_ama_appeal_with_ihp_pending.id).vso_ihp_complete).to eq(false)
      end
    end

    context "when there is an active legacy appeal with a completed InformalHearingPresentationTask" do
      let!(:open_ama_appeal_with_ihp_completed) { create(:appeal, :active, :with_completed_ihp_task) }
      it "a single record will be created in the Appeal States table" do
        subject.perform
        expect(AppealState.first.appeal_id).to eq(open_ama_appeal_with_ihp_completed.id)
        expect(AppealState.all.count).to eq(1)
      end

      it "the #{"vso_ihp_pending"} column will be set to FALSE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_ama_appeal_with_ihp_completed.id).vso_ihp_pending).to eq(false)
      end

      it "the #{"vso_ihp_complete"} column will be set to TRUE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_ama_appeal_with_ihp_completed.id).vso_ihp_complete).to eq(true)
      end
    end

    context "when there is an active AMA Appeal with an active IhpColocatedTask" do
      let!(:open_ama_appeal_with_ihp_colocated_pending) { create(:appeal, :active, :with_ihp_colocated_task) }
      it "a single record will be inserted into the Appeal States table" do
        subject.perform
        expect(
          AppealState.find_by(
            appeal_id: open_ama_appeal_with_ihp_colocated_pending.id,
            appeal_type: open_ama_appeal_with_ihp_colocated_pending.class.to_s
          ).appeal_id
        ).to eq(open_ama_appeal_with_ihp_colocated_pending.id)
        expect(AppealState.all.count).to eq(1)
      end

      it "the #{"vso_ihp_pending"} column will be set to TRUE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_ama_appeal_with_ihp_colocated_pending.id).vso_ihp_pending).to eq(true)
      end

      it "the #{"vso_ihp_complete"} column will be set to FALSE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_ama_appeal_with_ihp_colocated_pending.id).vso_ihp_complete).to eq(false)
      end
    end

    context "when there is an active AMA Appeal with a completed IhpColocatedTask" do
      let!(:open_ama_appeal_with_ihp_colocated_completed) { create(:appeal, :active, :with_completed_ihp_colocated_task) }
      it "a single record will be inserted into the Appeal States table" do
        subject.perform
        expect(
          AppealState.find_by(
            appeal_id: open_ama_appeal_with_ihp_colocated_completed.id,
            appeal_type: open_ama_appeal_with_ihp_colocated_completed.class.to_s
          ).appeal_id
        ).to eq(open_ama_appeal_with_ihp_colocated_completed.id)
        expect(AppealState.all.count).to eq(1)
      end

      it "the #{"vso_ihp_pending"} column will be set to FALSE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_ama_appeal_with_ihp_colocated_completed.id).vso_ihp_pending).to eq(false)
      end

      it "the #{"vso_ihp_complete"} column will be set to TRUE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_ama_appeal_with_ihp_colocated_completed.id).vso_ihp_complete).to eq(true)
      end
    end

    context "when there is an active legacy appeal with NO IhpColocatedTask(s) OR InformalHearingPresentationTask(s)" do
      let!(:open_ama_appeal) { create(:appeal, :active) }
      it "a single record will be created in the Appeal States table" do
        subject.perform
        expect(AppealState.first.appeal_id).to eq(open_ama_appeal.id)
        expect(AppealState.all.count).to eq(1)
      end

      it "the #{"vso_ihp_pending"} column will be set to FALSE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_ama_appeal.id).vso_ihp_pending).to eq(false)
      end

      it "the #{"vso_ihp_complete"} column will be set to FALSE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_ama_appeal.id).vso_ihp_complete).to eq(false)
      end
    end
  end

  describe "#map_appeal_hearing_postponed_state(appeal)" do
    let!(:scheduled_hearing) { create(:hearing) }
    let!(:postponed_hearing) { create(:hearing, :postponed) }
    let(:postponed_appeal) { postponed_hearing.appeal }
    let(:appeal) { scheduled_hearing.appeal }
    let(:second_hearing) { create(:hearing, appeal: postponed_appeal)}
    context "When the last hearing has a disposition of postponed" do
      it "returns the correct hash with a boolean value of true" do
        expect(subject.send(:map_appeal_hearing_postponed_state, postponed_appeal)).to eq(hearing_postponed: true)
      end
    end

    context "When the last hearing does not have a disposition of postponed" do
      it "returns the correct hash with a boolean value of false" do
        expect(subject.send(:map_appeal_hearing_postponed_state, appeal)).to eq(hearing_postponed: false)
      end
    end

    context "When there are multiple hearings associated with an appeal and the last one is postponed" do
      it "returns the correct hash with a boolean value of true" do
        second_hearing.update(disposition: "postponed")
        expect(subject.send(:map_appeal_hearing_postponed_state, postponed_appeal)).to eq(hearing_postponed: true)
      end
    end

    context "When there are multiple hearings associated with an appeal and the last one is not postponed" do
      it "returns the correct hash with a boolean value of false" do
        second_hearing
        expect(subject.send(:map_appeal_hearing_postponed_state, postponed_appeal)).to eq(hearing_postponed: false)
      end
    end
  end
end
