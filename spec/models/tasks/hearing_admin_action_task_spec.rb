# frozen_string_literal: true

describe HearingAdminActionTask, :postgres do
  let!(:veteran) { create(:veteran) }
  let!(:appeal) { create(:appeal, veteran: veteran) }
  let!(:hearings_management_user) { create(:hearings_coordinator) }

  context "create a new HearingAdminActionTask" do
    let!(:parent_task) { create(:schedule_hearing_task, appeal: appeal) }
    let(:task_params) { { appeal: appeal, parent_id: parent_task.id } }

    before do
      HearingsManagement.singleton.add_user(hearings_management_user)
      RequestStore[:current_user] = hearings_management_user
    end

    subject do
      # use a HearingAdminActionTask subclass, because objects are never created with the parent class
      HearingAdminActionIncarceratedVeteranTask.create_from_params(task_params, hearings_management_user)
    end

    it "is assigned to the HearingsManagement org by default" do
      expect(subject.assigned_to_type).to eq "Organization"
      expect(subject.assigned_to).to eq HearingsManagement.singleton
    end

    context "a user is explicitly assigned" do
      let(:task_params) do
        {
          appeal: appeal,
          parent_id: parent_task.id,
          assigned_to_type: "User",
          assigned_to_id: hearings_management_user.id
        }
      end

      it "is assigned to the user" do
        expect(subject.assigned_to_type).to eq "User"
        expect(subject.assigned_to).to eq hearings_management_user
      end
    end

    it "has actions available to the hearings managment org member" do
      expect(subject.available_actions_unwrapper(hearings_management_user).count).to be > 0
    end

    context "there is a hearing admin org user" do
      let(:hearing_admin_user) { create(:user, station_id: 101) }

      before do
        HearingAdmin.singleton.add_user(hearing_admin_user)
      end

      it "has no actions available to the hearing admin user" do
        expect(subject.available_actions_unwrapper(hearing_admin_user).count).to eq 0
      end
    end
  end
end
