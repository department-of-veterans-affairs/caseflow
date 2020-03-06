# frozen_string_literal: true

RSpec.shared_examples "Address Verify Task for Appeal" do
  let!(:user) { create(:hearings_coordinator) }
  let(:distribution_task) { create(:distribution_task, appeal: appeal) }
  let(:parent_hearing_task) { create(:hearing_task, parent: distribution_task, appeal: appeal) }
  let!(:schedule_hearing_task) { create(:schedule_hearing_task, :completed, appeal: appeal) }
  let!(:verify_address_task) do
    create(
      :hearing_admin_action_verify_address_task,
      parent: parent_hearing_task,
      appeal: appeal,
      assigned_to: HearingsManagement.singleton,
      assigned_to_type: "Organization"
    )
  end

  context "as a hearing admin user" do
    before do
      HearingAdmin.singleton.add_user(user)

      RequestStore[:current_user] = user
    end

    it "has cancel action available" do
      available_actions = verify_address_task.available_actions(user)

      expect(available_actions.length).to eq 1
      expect(available_actions)
        .to include(Constants.TASK_ACTIONS.CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE.to_h)
    end
  end

  context "as hearings management user" do
    before do
      HearingsManagement.singleton.add_user(user)

      RequestStore[:current_user] = user
    end

    it "has assign action available" do
      available_actions = verify_address_task.available_actions(user)

      expect(available_actions.length).to eq 1
      expect(available_actions).to include(Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h)
    end
  end

  context "after update" do
    it "finds closest_ro for veteran when completed" do
      verify_address_task.update!(status: Constants.TASK_STATUSES.completed)

      expect(verify_address_task.status).to eq Constants.TASK_STATUSES.completed
      expect(RegionalOffice::ROS).to include(appeal.class.first.closest_regional_office)
    end

    it "throws an access error trying to update from params with random user" do
      user = create(:user)

      expect { verify_address_task.update_from_params({}, user) }.to raise_error(
        Caseflow::Error::ActionForbiddenError
      )
    end

    it "updates ro and ahls when cancelled" do
      HearingAdmin.singleton.add_user(user)

      RequestStore[:current_user] = user

      payload = {
        "status": Constants.TASK_STATUSES.cancelled,
        "business_payloads": {
          "values": {
            "regional_office_value": "RO50"
          }
        }
      }
      verify_address_task.update_from_params(payload, user)

      expect(verify_address_task.status).to eq Constants.TASK_STATUSES.cancelled
      expect(appeal.class.first.closest_regional_office).to eq "RO50"
      expect(appeal.class.first.available_hearing_locations.count).to eq 1
    end
  end
end

describe HearingAdminActionVerifyAddressTask, :all_dbs do
  describe "Address Verify Workflow with Legacy Appeal" do
    let!(:appeal) { create(:legacy_appeal, :with_veteran_address, vacols_case: create(:case)) }
    let!(:appeal_id) { appeal.vacols_id }

    include_examples "Address Verify Task for Appeal"
  end

  describe "Address Verify Workflow with AMA Appeal" do
    let!(:veteran) { create(:veteran) }
    let!(:appeal) { create(:appeal, :hearing_docket, veteran: veteran) }
    let!(:appeal_id) { appeal.uuid }

    include_examples "Address Verify Task for Appeal"
  end
end
