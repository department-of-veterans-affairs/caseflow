# frozen_string_literal: true

describe HearingAdminActionTask do
  let!(:veteran) { create(:veteran) }
  let!(:appeal) { create(:appeal, veteran: veteran) }

  context "create a new HearingAdminActionTask" do
    let!(:hearings_management_user) { FactoryBot.create(:hearings_coordinator) }
    let!(:parent_task) { FactoryBot.create(:schedule_hearing_task, appeal: appeal) }
    let(:task_params) { { appeal: appeal, parent_id: parent_task.id } }

    before do
      OrganizationsUser.add_user_to_organization(hearings_management_user, HearingsManagement.singleton)
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
      let(:hearing_admin_user) { FactoryBot.create(:user, station_id: 101) }

      before do
        OrganizationsUser.add_user_to_organization(hearing_admin_user, HearingAdmin.singleton)
      end

      it "has no actions available to the hearing admin user" do
        expect(subject.available_actions_unwrapper(hearing_admin_user).count).to eq 0
      end
    end
  end

  describe "VerifyAddressTask after update" do
    let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal) }
    let!(:verify_address_task) do
      HearingAdminActionVerifyAddressTask.create!(
        appeal: appeal,
        parent: schedule_hearing_task,
        assigned_to: HearingsManagement.singleton
      )
    end

    it "finds closest_ro for veteran" do
      VADotGovService = Fakes::VADotGovService
      verify_address_task.update!(status: "completed")

      expect(Appeal.first.closest_regional_office).to eq "RO17"
      expect(Appeal.first.available_hearing_locations.count).to eq 2
    end
  end
end
