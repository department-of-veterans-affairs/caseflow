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

    context "when there are only CANCELLED Legacy Appeals in the database" do
      let!(:cancelled_legacy_appeals) do
        [
          create(:legacy_appeal, :with_cancelled_root_task, vacols_id: "11"),
          create(:legacy_appeal, :with_cancelled_root_task, vacols_id: "21"),
          create(:legacy_appeal, :with_cancelled_root_task, vacols_id: "31"),
          create(:legacy_appeal, :with_cancelled_root_task, vacols_id: "41"),
          create(:legacy_appeal, :with_cancelled_root_task, vacols_id: "51")
        ]
      end
      it "5 records will be added to the Appeal States table" do
        subject.perform
        expect(AppealState.all.count).to eq(cancelled_legacy_appeals.count)
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
    let!(:legacy_appeal) { create(:legacy_appeal) }
    let(:error) { StandardError }
    context "When an error is raised" do
      it "will log error and continue" do
        allow(Rails.logger).to receive(:error)
        allow(subject).to receive(:map_appeal_ihp_state).with(legacy_appeal).and_raise(error)
        subject.send(:add_record_to_appeal_states_table, legacy_appeal)
        expect(Rails.logger).to have_received(:error).with(
          "FetchAllActiveLegacyAppealsJob::Error - An Appeal State record for #{legacy_appeal&.class} "\
          "ID #{legacy_appeal&.id} was unable to be created/updated because of #{error}"
        )
      end
    end
  end

  describe "map appeal state with hearing scheduled" do
    # rubocop:disable Layout/LineLength
    context "appeals with hearings scheduled tasks" do
      let!(:legacy_hearing) { create(:legacy_hearing) }
      let!(:legacy_hearing_held) { create(:legacy_hearing, disposition: "H") }
      it "hearings with nil disposition should map the hearing scheduled appeal state to true" do
        expect(subject.send(:map_appeal_hearing_scheduled_state, legacy_hearing.appeal)).to eq(hearing_scheduled: true)
      end

      it "no hearings with nil disposition should map the hearing scheduled appeal state to false" do
        expect(subject.send(:map_appeal_hearing_scheduled_state, legacy_hearing_held.appeal)).to eq(hearing_scheduled: false)
      end
    end

    context "appeals hearings with multiple hearings scheduled" do
      let!(:legacy_appeal) do
        create(:legacy_appeal, :with_veteran,
               vacols_case: create(:case, :aod))
      end
      let!(:old_case_hearing) { create(:case_hearing, folder_nr: legacy_appeal.vacols_id) }
      let!(:new_case_hearing) { create(:case_hearing, folder_nr: legacy_appeal.vacols_id) }
      let!(:old_hearing) { create(:legacy_hearing, disposition: "C") }
      let!(:new_hearing) { create(:legacy_hearing) }
      it "should still map appeal state to true if most recent hearing has nil disposition" do
        expect(subject.send(:map_appeal_hearing_scheduled_state, legacy_appeal)).to eq(hearing_scheduled: true)
      end

      it "should not map appeal state to true if none of the hearings have nil disposition" do
        old_case_hearing.update(hearing_disp: "P")
        new_case_hearing.update(hearing_disp: "H")
        old_hearing.class.repository.load_vacols_data(old_hearing)
        new_hearing.class.repository.load_vacols_data(new_hearing)
        expect(subject.send(:map_appeal_hearing_scheduled_state, legacy_appeal)).to eq(hearing_scheduled: false)
      end
    end

    context "appeals without any hearing scheduled tasks" do
      let!(:legacy_appeal) do
        create(:legacy_appeal, :with_veteran,
               vacols_case: create(:case, :aod))
      end
      it "should not map appeal state to true if there arent any hearings" do
        subject.send(:map_appeal_hearing_scheduled_state, legacy_appeal)
        expect(subject.send(:map_appeal_hearing_scheduled_state, legacy_appeal)).to eq(hearing_scheduled: false)
      end
    end
  end

  describe "#map_appeal_ihp_state" do
    context "when there is an active legacy appeal with an active IhpColocated Task" do
      let!(:open_legacy_appeal_with_ihp_pending) { create(:legacy_appeal, :with_root_task, :with_active_ihp_colocated_task) }
      it "a single record will be inserted into the Appeal States table" do
        subject.perform
        expect(
          AppealState.find_by(
            appeal_id: open_legacy_appeal_with_ihp_pending.id,
            appeal_type: open_legacy_appeal_with_ihp_pending.class.to_s
          ).appeal_id
        ).to eq(open_legacy_appeal_with_ihp_pending.id)
        expect(AppealState.all.count).to eq(1)
      end

      it "the #{"vso_ihp_pending"} column will be set to TRUE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_legacy_appeal_with_ihp_pending.id).vso_ihp_pending).to eq(true)
      end

      it "the #{"vso_ihp_complete"} column will be set to FALSE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_legacy_appeal_with_ihp_pending.id).vso_ihp_complete).to eq(false)
      end
    end

    context "when there is an active legacy appeal with completed IhpColocatedTask(s)" do
      let!(:open_legacy_appeal_with_ihp_completed) { create(:legacy_appeal, :with_root_task, :with_completed_ihp_colocated_task) }
      it "a single record will be created in the Appeal States table" do
        subject.perform
        expect(AppealState.first.appeal_id).to eq(open_legacy_appeal_with_ihp_completed.id)
        expect(AppealState.all.count).to eq(1)
      end

      it "the #{"vso_ihp_pending"} column will be set to FALSE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_legacy_appeal_with_ihp_completed.id).vso_ihp_pending).to eq(false)
      end

      it "the #{"vso_ihp_complete"} column will be set to TRUE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_legacy_appeal_with_ihp_completed.id).vso_ihp_complete).to eq(true)
      end
    end

    context "when there is an active legacy appeal with NO IhpColocatedTask(s)" do
      let!(:open_legacy_appeal) { create(:legacy_appeal, :with_root_task) }
      it "a single record will be created in the Appeal States table" do
        subject.perform
        expect(AppealState.first.appeal_id).to eq(open_legacy_appeal.id)
        expect(AppealState.all.count).to eq(1)
      end

      it "the #{"vso_ihp_pending"} column will be set to FALSE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_legacy_appeal.id).vso_ihp_pending).to eq(false)
      end

      it "the #{"vso_ihp_complete"} column will be set to FALSE" do
        subject.perform
        expect(AppealState.find_by(appeal_id: open_legacy_appeal.id).vso_ihp_complete).to eq(false)
      end
    end
  end

  describe "#map_appeal_privacy_act_state(appeal)" do
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
    let(:foia1) { create(:colocated_task, :foia, appeal: appeal, instructions: ["test"]) }
    let(:foia2) { create(:colocated_task, :foia, appeal: appeal, instructions: ["test2"]) }
    let(:foia3) { create(:colocated_task, :foia, appeal: appeal, instructions: ["test3"]) }
    context "When there are no privacy act tasks" do
      it "returns the correct hash with two false values" do
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: false)
      end
    end

    context "When there is only one privacy act task (completed)" do
      it "returns the correct hash with pending: false and complete: true" do
        foia1.update(status: Constants.TASK_STATUSES.completed)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: true)
      end
    end

    context "When there is only one privacy act task (pending)" do
      it "returns the correct hash with pending: true and complete: false" do
        foia1
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: true, privacy_act_complete: false)
      end
    end

    context "When there is only one privacy act task (cancelled)" do
      it "returns the correct hash with pending: false and complete: false" do
        foia1.update(status: Constants.TASK_STATUSES.cancelled)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: false)
      end
    end

    context "When there are multiple privacy act tasks (all completed)" do
      it "returns the correct hash with pending: false and complete: true" do
        foia1.update(status: Constants.TASK_STATUSES.completed)
        foia2.update(status: Constants.TASK_STATUSES.completed)
        foia3.update(status: Constants.TASK_STATUSES.completed)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: true)
      end
    end

    context "When there are multiple privacy act tasks (all cancelled)" do
      it "returns the correct hash with pending: false and complete: false" do
        foia1.update(status: Constants.TASK_STATUSES.cancelled)
        foia2.update(status: Constants.TASK_STATUSES.cancelled)
        foia3.update(status: Constants.TASK_STATUSES.cancelled)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: false)
      end
    end

    context "When there are multiple privacy act tasks (at least one pending)" do
      it "returns the correct hash with pending: true and complete: false" do
        foia1
        foia2.update(status: Constants.TASK_STATUSES.completed)
        foia3.update(status: Constants.TASK_STATUSES.cancelled)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: true, privacy_act_complete: false)
      end
    end

    context "When there are mutliple privacy act tasks (mix of completed and cancelled)" do
      it "returns the correct hash with pending: false and complete: true" do
        foia1.update(status: Constants.TASK_STATUSES.completed)
        foia2.update(status: Constants.TASK_STATUSES.cancelled)
        foia3.update(status: Constants.TASK_STATUSES.completed)
        expect(subject.send(:map_appeal_privacy_act_state, appeal)).to eq(privacy_act_pending: false, privacy_act_complete: true)
      end
    end
  end

  describe "#map_appeal_hearing_postponed_state(appeal)" do
    let!(:scheduled_hearing) { create(:legacy_hearing) }
    let!(:postponed_hearing) { create(:legacy_hearing, disposition: "P") }
    let(:postponed_appeal) { postponed_hearing.appeal }
    let(:appeal) { scheduled_hearing.appeal }
    let(:new_case_hearing) { create(:case_hearing, folder_nr: postponed_appeal.vacols_id) }
    let(:empty_appeal) { create(:legacy_appeal) }
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
        new_case_hearing.update(hearing_disp: "P")
        expect(subject.send(:map_appeal_hearing_postponed_state, postponed_appeal)).to eq(hearing_postponed: true)
      end
    end

    context "When there are multiple hearings associated with an appeal and the last one is not postponed" do
      it "returns the correct hash with a boolean value of false" do
        new_case_hearing
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
    let!(:hearing) { create(:legacy_hearing) }
    let!(:hearing_withdrawn) { create(:legacy_hearing, disposition: "C") }
    let(:withdrawn_legacy_appeal) { hearing_withdrawn.appeal }
    let(:legacy_appeal) { hearing.appeal }
    let(:new_case_hearing) { create(:case_hearing, folder_nr: withdrawn_legacy_appeal.vacols_id) }
    context "when there is a Legacy Appeal and the most recent hearing dispostion status is 'cancelled'" do
      it "returns correct key value hearing_withdrawn: true" do
        expect(subject.send(:map_appeal_hearing_withdrawn_state, withdrawn_legacy_appeal)).to eq(hearing_withdrawn: true)
      end
    end

    context "when there is a Legacy Appeal and the most recent hearing dispostion status is not 'cancelled'" do
      it "returns correct key value hearing_withdrawn: false" do
        expect(subject.send(:map_appeal_hearing_withdrawn_state, legacy_appeal)).to eq(hearing_withdrawn: false)
      end
    end

    context "when there is a Legacy Appeal with multiple hearings and the most recent hearing dispostion status is not 'cancelled'" do
      it "returns correct key value hearing_withdrawn: false" do
        new_case_hearing
        expect(subject.send(:map_appeal_hearing_withdrawn_state, withdrawn_legacy_appeal)).to eq(hearing_withdrawn: false)
      end
    end

    context "when there is a Legacy Appeal with multiple hearings and the most recent hearing dispostion status is 'cancelled'" do
      it "returns correct key value hearing_withdrawn: true" do
        new_case_hearing.update(hearing_disp: "C")
        expect(subject.send(:map_appeal_hearing_withdrawn_state, withdrawn_legacy_appeal)).to eq(hearing_withdrawn: true)
      end
    end
  end

  describe "#map_appeal_cancelled_state(appeal)" do
    let(:legacy_appeal) { create(:legacy_appeal, :with_root_task) }
    let(:legacy_appeal_cancelled) { create(:legacy_appeal, :with_cancelled_root_task) }
    let(:la_rt_nil) { create(:legacy_appeal) }

    context "when there is a Legacy Appeal and the root_task has a status of 'cancelled'" do
      it "returns correct key value appeal_cancelled: true" do
        expect(subject.send(:map_appeal_cancelled_state, legacy_appeal_cancelled)).to eq(appeal_cancelled: true)
      end
    end

    context "when there is a Legacy Appeal and the root_task has a status that is not 'cancelled'" do
      it "returns correct key value appeal_cancelled: false" do
        expect(subject.send(:map_appeal_cancelled_state, legacy_appeal)).to eq(appeal_cancelled: false)
      end
    end

    context "when there is a Legacy Appeal and the root_task is 'nil'" do
      it "returns correct key value appeal_cancelled: false" do
        expect(subject.send(:map_appeal_cancelled_state, la_rt_nil)).to eq(appeal_cancelled: false)
      end
    end
  end


  describe "map appeal docketed state" do
    context "legacy appeals" do
      let!(:legacy_appeal) do
        create(:legacy_appeal, :with_veteran,
               vacols_case: create(:case, :aod))
      end

      it "returns appeal docketed: true" do
        legacy_appeal.case_record.update(bfcurloc: "01")
        expect(subject.send(:map_appeal_docketed_state, legacy_appeal)).to eq(appeal_docketed: true)
      end

      it "return appeal docketed: false" do
        expect(subject.send(:map_appeal_docketed_state, legacy_appeal)).to eq(appeal_docketed: false)
      end
    end
  end

  describe "#map_appeal_hearing_scheduled_in_error_state(appeal)" do
    let!(:scheduled_hearing) { create(:legacy_hearing) }
    let!(:error_hearing) { create(:legacy_hearing, disposition: "E") }
    let(:error_appeal) { error_hearing.appeal }
    let(:appeal) { scheduled_hearing.appeal }
    let(:new_case_hearing) { create(:case_hearing, folder_nr: error_appeal.vacols_id) }
    let(:empty_appeal) { create(:legacy_appeal) }
    context "When the last hearing has a disposition of scheduled in error" do
      it "returns the correct hash with a boolean value of true" do
        expect(subject.send(:map_appeal_hearing_scheduled_in_error_state, error_appeal)).to eq(scheduled_in_error: true)
      end
    end

    context "When the last hearing does not have a disposition of scheduled in error" do
      it "returns the correct hash with a boolean value of false" do
        expect(subject.send(:map_appeal_hearing_scheduled_in_error_state, appeal)).to eq(scheduled_in_error: false)
      end
    end

    context "When there are multiple hearings associated with an appeal and the last one is scheduled in error" do
      it "returns the correct hash with a boolean value of true" do
        new_case_hearing.update(hearing_disp: "E")
        expect(subject.send(:map_appeal_hearing_scheduled_in_error_state, error_appeal)).to eq(scheduled_in_error: true)
      end
    end

    context "When there are multiple hearings associated with an appeal and the last one is not postponed" do
      it "returns the correct hash with a boolean value of false" do
        new_case_hearing
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
# rubocop:enable Layout/LineLength
