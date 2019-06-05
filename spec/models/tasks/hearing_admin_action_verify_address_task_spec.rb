# frozen_string_literal: true

require "rails_helper"

RSpec.feature HearingAdminActionVerifyAddressTask do
  let!(:veteran) { create(:veteran) }
  let!(:appeal) { create(:appeal, :hearing_docket, veteran: veteran) }
  let!(:user) { create(:hearings_coordinator) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:distribution_task) { create(:distribution_task, appeal: appeal, parent: root_task) }
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
      OrganizationsUser.add_user_to_organization(user, HearingAdmin.singleton)

      RequestStore[:current_user] = user
    end

    it "has cancel action available" do
      available_actions = verify_address_task.available_actions(user)

      expect(available_actions.length).to eq 1
      expect(available_actions).to include(Constants.TASK_ACTIONS.CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE.to_h)
    end
  end

  context "as hearings management user" do
    before do
      OrganizationsUser.add_user_to_organization(user, HearingsManagement.singleton)

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
      expect(Appeal.first.closest_regional_office).to eq "RO17"
      expect(Appeal.first.available_hearing_locations.count).to eq 2
    end

    it "throws an access error trying to update from params with random user" do
      user = FactoryBot.create(:user)

      expect { verify_address_task.update_from_params({}, user) }.to raise_error(
        Caseflow::Error::ActionForbiddenError
      )
    end

    it "updates ro and ahls when cancelled" do
      OrganizationsUser.add_user_to_organization(user, HearingAdmin.singleton)

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
      expect(Appeal.first.closest_regional_office).to eq "RO50"
      expect(Appeal.first.available_hearing_locations.count).to eq 1
    end
  end

  describe "UI tests" do
    let(:instructions_text) { "This is why I want to cancel the task!" }
    
    context "with a hearing admin member" do
      before do
        OrganizationsUser.add_user_to_organization(user, HearingAdmin.singleton)

        User.authenticate!(user: user)

        visit("/queue/appeals/#{appeal.uuid}")
      end

      it "has 'Cancel task and assign Regional Office' option" do
        expect(page).to have_content("Verify Address")

        click_dropdown(text: Constants.TASK_ACTIONS.CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE.label)
      end

      context "in cancel task modal" do
        before do
          click_dropdown(text: Constants.TASK_ACTIONS.CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE.label)
        end

        it "has Regional Office dropdown and notes field" do
          expect(page).to have_field("regionalOffice")
          expect(page).to have_field("notes")
        end

        it "Regional Office and notes are editable" do
          click_dropdown(text: "Atlanta, GA")
          fill_in("Notes", with: instructions_text)
        end

        it "can't submit form without specifying a Regional Office" do
          click_button("Confirm")

          expect(page).to have_content COPY::REGIONAL_OFFICE_REQUIRED_MESSAGE
        end

        it "can submit form with Regional Office and no notes" do
          click_dropdown(text: "Atlanta, GA")

          click_button("Confirm")

          expect(page).to have_content COPY::CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_UPDATED_SUCCESS_TITLE
        end

        it "can submit form with Regional Office and notes" do
          click_dropdown(text: "Atlanta, GA")
          fill_in("Notes", with: instructions_text)

          click_button("Confirm")

          expect(page).to have_content COPY::CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_UPDATED_SUCCESS_TITLE
        end
      end
    end

    context "with a regular member" do
      before do
        User.authenticate!(user: user)
      end

      it "has no actions" do
        visit("/queue/appeals/#{appeal.uuid}")

        expect(page).to have_content("Verify Address")
        expect(page).not_to have_selector(".Select-control")
      end
    end
  end
end
