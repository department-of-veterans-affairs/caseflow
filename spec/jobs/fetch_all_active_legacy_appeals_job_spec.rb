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

  describe "#map_appeal_hearing_postponed_state(appeal)" do
    let!(:scheduled_hearing) { create(:legacy_hearing) }
    let!(:postponed_hearing) { create(:legacy_hearing, disposition: "P") }
    let(:postponed_appeal) { postponed_hearing.appeal }
    let(:appeal) { scheduled_hearing.appeal }
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
  end
end
