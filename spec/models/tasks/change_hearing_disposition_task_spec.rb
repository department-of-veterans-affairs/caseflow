# frozen_string_literal: true

describe ChangeHearingDispositionTask, :postgres do
  let(:appeal) { create(:appeal, :hearing_docket) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:distribution_task) { create(:distribution_task, appeal: appeal, parent: root_task) }
  let(:hearing_task) { create(:hearing_task, parent: distribution_task, appeal: appeal) }

  context "create a new ChangeHearingDispositionTask" do
    let(:task_params) { { appeal: appeal, parent: hearing_task } }

    subject { ChangeHearingDispositionTask.create!(**task_params) }

    it "is assigned to the HearingAdmin org by default" do
      expect(subject.assigned_to_type).to eq "Organization"
      expect(subject.assigned_to).to eq HearingAdmin.singleton
    end

    context "there is a hearings management org user" do
      let!(:hearing_admin_user) { create(:hearings_coordinator) }

      before do
        HearingAdmin.singleton.add_user(hearing_admin_user)
      end

      it "has actions available to the hearings admin org member" do
        expect(subject.available_actions_unwrapper(hearing_admin_user).count).to be > 0
      end
    end

    context "there is a hearings management org user" do
      let(:hearings_management_user) { create(:user, station_id: 101) }

      before do
        HearingsManagement.singleton.add_user(hearings_management_user)
      end

      it "has no actions available" do
        expect(subject.available_actions_unwrapper(hearings_management_user).count).to eq 0
      end
    end
  end
end
