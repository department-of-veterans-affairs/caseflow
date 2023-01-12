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
    let!(:appeal) { create(:appeal, :active) }
    let(:error) { StandardError }
    context "When an error is raised" do
      it "will log error and continue" do
        allow(Rails.logger).to receive(:error)
        allow(subject).to receive(:map_appeal_ihp_state).with(appeal).and_raise(error)
        subject.send(:add_record_to_appeal_states_table, appeal)
        expect(Rails.logger).to have_received(:error).with(
          "FetchAllActiveAmaAppealsJob::Error - An Appeal State record for #{appeal&.class} ID "\
          "#{appeal&.id} was unable to be created/updated because of #{error}"
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

      it "should not map appeal state to true if none of the hearings have nil disposition" do
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

  describe "#map_appeal_privacy_act_state(appeal)" do
    let(:appeal) { create(:appeal) }
    let(:privacy_act1) { create(:privacy_act_task, appeal: appeal) }
    let(:privacy_act2) { create(:privacy_act_task, appeal: appeal) }
    let(:privacy_act3) { create(:privacy_act_task, appeal: appeal) }
    context "When there are no privacy act tasks" do
      it "returns the correct hash with two false values" do
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: false)
      end
    end

    context "When there is only one privacy act task (completed)" do
      it "returns the correct hash with pending: false and complete: true" do
        privacy_act1.update(status: Constants.TASK_STATUSES.completed)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: true)
      end
    end

    context "When there is only one privacy act task (pending)" do
      it "returns the correct hash with pending: true and complete: false" do
        privacy_act1
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: true, privacy_act_complete: false)
      end
    end

    context "When there is only one privacy act task (cancelled)" do
      it "returns the correct hash with pending: false and complete: false" do
        privacy_act1.update(status: Constants.TASK_STATUSES.cancelled)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: false)
      end
    end

    context "When there are multiple privacy act tasks (all completed)" do
      it "returns the correct hash with pending: false and complete: true" do
        privacy_act1.update(status: Constants.TASK_STATUSES.completed)
        privacy_act2.update(status: Constants.TASK_STATUSES.completed)
        privacy_act3.update(status: Constants.TASK_STATUSES.completed)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: true)
      end
    end

    context "When there are multiple privacy act tasks (all cancelled)" do
      it "returns the correct hash with pending: false and complete: false" do
        privacy_act1.update(status: Constants.TASK_STATUSES.cancelled)
        privacy_act2.update(status: Constants.TASK_STATUSES.cancelled)
        privacy_act3.update(status: Constants.TASK_STATUSES.cancelled)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: false)
      end
    end

    context "When there are multiple privacy act tasks (at least one pending)" do
      it "returns the correct hash with pending: true and complete: false" do
        privacy_act1
        privacy_act2.update(status: Constants.TASK_STATUSES.completed)
        privacy_act3.update(status: Constants.TASK_STATUSES.cancelled)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: true, privacy_act_complete: false)
      end
    end

    context "When there are mutliple privacy act tasks (mix of completed and cancelled)" do
      it "returns the correct hash with pending: false and complete: true" do
        privacy_act1.update(status: Constants.TASK_STATUSES.completed)
        privacy_act2.update(status: Constants.TASK_STATUSES.cancelled)
        privacy_act3.update(status: Constants.TASK_STATUSES.completed)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: true)
      end
    end
  end

  describe "#map_appeal_hearing_postponed_state(appeal)" do
    let!(:scheduled_hearing) { create(:hearing) }
    let!(:postponed_hearing) { create(:hearing, :postponed) }
    let(:postponed_appeal) { postponed_hearing.appeal }
    let(:appeal) { scheduled_hearing.appeal }
    let(:second_hearing) { create(:hearing, appeal: postponed_appeal) }
    let(:empty_appeal) { create(:appeal) }
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

    context "When there are no hearings associated with an appeal" do
      it "returns the correct hash with a boolean value of false" do
        expect(subject.send(:map_appeal_hearing_postponed_state, empty_appeal)).to eq(hearing_postponed: false)
      end
    end
  end

  describe "#map_appeal_hearing_withdrawn_state(appeal)" do
    let!(:hearing) { create(:hearing) }
    let!(:hearing_withdrawn) { create(:hearing, :cancelled) }
    let(:second_hearing) { create(:hearing, appeal: appeal) }
    let(:withdrawn_appeal) { hearing_withdrawn.appeal }
    let(:appeal) { hearing.appeal }

    context "when there is an AMA Appeal and the most recent hearing dispostion status is 'cancelled'" do
      it "returns correct key value hearing_withdrawn: true" do
        expect(subject.send(:map_appeal_hearing_withdrawn_state, withdrawn_appeal)).to eq(hearing_withdrawn: true)
      end
    end

    context "when there is an AMA Appeal and the most recent hearing dispostion status is not 'cancelled'" do
      it "returns correct key value hearing_withdrawn: false" do
        expect(subject.send(:map_appeal_hearing_withdrawn_state, appeal)).to eq(hearing_withdrawn: false)
      end
    end

    context "when there is an active AMA Appeal with multiple hearings and the most recent disposition is 'cancelled'" do
      it "returns correct key value hearing_withdrawn: true" do
        second_hearing.update(disposition: "cancelled")
        expect(subject.send(:map_appeal_hearing_withdrawn_state, appeal)).to eq(hearing_withdrawn: true)
      end
    end

    context "when there is an active AMA Appeal with multiple hearings and the most recent disposition is not 'cancelled'" do
      it "returns correct key value hearing_withdrawn: false" do
        second_hearing
        expect(subject.send(:map_appeal_hearing_withdrawn_state, appeal)).to eq(hearing_withdrawn: false)
      end
    end
  end

  describe "#map_appeal_cancelled_state(appeal)" do
    let!(:task) { create(:root_task) }
    let!(:task_cancelled) { create(:root_task, :cancelled) }
    let!(:appeal_rt_nil) { create(:appeal) }
    let(:appeal_cancelled) { task_cancelled.appeal }
    let(:appeal) { task.appeal }

    context "when there is an AMA Appeal and the root_task has a status of 'cancelled'" do
      it "returns correct key value appeal_cancelled: true" do
        expect(subject.send(:map_appeal_cancelled_state, appeal_cancelled)).to eq(appeal_cancelled: true)
      end
    end

    context "when there is an AMA Appeal and the root_task has a status that is not 'cancelled'" do
      it "returns correct key value appeal_cancelled: false" do
        expect(subject.send(:map_appeal_cancelled_state, appeal)).to eq(appeal_cancelled: false)
      end
    end

    context "when there is an AMA Appeal and the root_task is 'nil'" do
      it "returns correct key value appeal_cancelled: false" do
        expect(subject.send(:map_appeal_cancelled_state, appeal_rt_nil)).to eq(appeal_cancelled: false)
      end
    end
  end

  describe "map appeal docketed state" do
    context "ama appeals" do
      let!(:appeal) { create(:appeal) }
      let!(:appeal_with_only_root_task) { create(:appeal) }
      let!(:appeal_with_no_tasks) { create(:appeal) }
      let!(:root_task) { create(:root_task, appeal: appeal_with_only_root_task) }
      let!(:distribution_task) { create(:distribution_task, appeal: appeal) }

      it "returns appeal docketed: true when there is a distribution task" do
        expect(subject.send(:map_appeal_docketed_state, appeal)).to eq(appeal_docketed: true)
      end

      it "returns appeal docketed: false when there are no distribution tasks" do
        expect(subject.send(:map_appeal_docketed_state, appeal_with_only_root_task)).to eq(appeal_docketed: false)
      end

      it "return appeal docketed: false when there are no tasks at all" do
        expect(subject.send(:map_appeal_docketed_state, appeal_with_no_tasks)).to eq(appeal_docketed: false)
      end
    end
  end

  describe "#map_appeal_hearing_scheduled_in_error_state(appeal)" do
    let!(:scheduled_hearing) { create(:hearing) }
    let!(:error_hearing) { create(:hearing, :scheduled_in_error) }
    let(:error_appeal) { error_hearing.appeal }
    let(:appeal) { scheduled_hearing.appeal }
    let(:second_hearing) { create(:hearing, appeal: error_appeal)}
    let(:empty_appeal) { create(:appeal) }
    context "When the last hearing has a disposition of postponed" do
      it "returns the correct hash with a boolean value of true" do
        expect(subject.send(:map_appeal_hearing_scheduled_in_error_state, error_appeal)).to eq(scheduled_in_error: true)
      end
    end

    context "When the last hearing does not have a disposition of postponed" do
      it "returns the correct hash with a boolean value of false" do
        expect(subject.send(:map_appeal_hearing_scheduled_in_error_state, appeal)).to eq(scheduled_in_error: false)
      end
    end

    context "When there are multiple hearings associated with an appeal and the last one is postponed" do
      it "returns the correct hash with a boolean value of true" do
        second_hearing.update(disposition: Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error)
        expect(subject.send(:map_appeal_hearing_scheduled_in_error_state, error_appeal)).to eq(scheduled_in_error: true)
      end
    end

    context "When there are multiple hearings associated with an appeal and the last one is not postponed" do
      it "returns the correct hash with a boolean value of false" do
        second_hearing
        expect(subject.send(:map_appeal_hearing_scheduled_in_error_state, error_appeal)).to eq(scheduled_in_error: false)
      end
    end

    context "When there are no hearings associated with an appeal" do
      it "returns the correct hash with a boolean value of false" do
        expect(subject.send(:map_appeal_hearing_scheduled_in_error_state, empty_appeal)).to eq(scheduled_in_error: false)
      end
    end
  end
end
