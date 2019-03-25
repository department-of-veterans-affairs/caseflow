# frozen_string_literal: true

describe Hearing do
  context "create" do
    let!(:hearing_day) { create(:hearing_day) }

    before do
      12.times do
        create(:hearing, hearing_day: hearing_day)
      end

      hearing_day.reload
    end

    it "prevents user from overfilling a hearing day" do
      expect do
        Hearing.create!(appeal: create(:appeal), hearing_day: hearing_day, scheduled_time: "8:30 am est")
      end.to raise_error(Hearing::HearingDayFull)
    end
  end

  context "disposition_editable" do
    let!(:hearing) { create(:hearing, :with_tasks) }
    subject { hearing.disposition_editable }

    context "when the hearing has an open disposition task" do
      it { is_expected.to eq(true) }
    end

    context "when the hearing has a cancelled disposition task" do
      before do
        hearing.disposition_task.update!(status: Constants.TASK_STATUSES.cancelled)
      end

      it { is_expected.to eq(false) }
    end

    context "when the hearing has a disposition task with children" do
      let!(:transcription_task) { create(:transcription_task, parent: hearing.disposition_task) }

      it { is_expected.to eq(false) }
    end
  end

  context "assigned_to_vso?" do
    let(:hearing) { create(:hearing, :with_tasks) }
    let(:vso) { create(:vso) }
    let(:user) { create(:user, :vso_role) }
    let!(:track_veteran_task) { create(:track_veteran_task, appeal: hearing.appeal, assigned_to: vso) }

    subject { hearing.assigned_to_vso?(user) }

    context "when the hearing is not assigned a vso" do
      it { is_expected.to eq(false) }
    end

    context "when the hearing is assigned a vso" do
      before do
        OrganizationsUser.add_user_to_organization(user, vso)
      end

      it { is_expected.to eq(true) }
    end
  end
end
