# frozen_string_literal: true

RSpec.shared_examples "Address Verify Task Frontend Workflow" do
  let!(:user) { create(:hearings_coordinator) }
  let(:distribution_task) { create(:distribution_task, appeal: appeal) }
  let(:parent_hearing_task) { create(:hearing_task, parent: distribution_task) }
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

  describe "UI tests" do
    let(:instructions_text) { "This is why I want to cancel the task!" }

    context "with a hearing admin member" do
      before do
        HearingAdmin.singleton.add_user(user)

        User.authenticate!(user: user)

        visit("/queue/appeals/#{appeal_id}")
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
          expect(page).to have_field("regional-office")
          expect(page).to have_field("notes")
        end

        it "Regional Office and notes are editable" do
          click_dropdown({ text: "Atlanta, GA" }, find(".cf-modal-body"))
          fill_in("Notes", with: instructions_text)
        end

        it "can't submit form without specifying a Regional Office" do
          click_button("Confirm")

          expect(page).to have_content COPY::REGIONAL_OFFICE_REQUIRED_MESSAGE
        end

        it "can submit form with Regional Office and no notes" do
          click_dropdown({ text: "Atlanta, GA" }, find(".cf-modal-body"))

          click_button("Confirm")

          expect(page)
            .to have_content COPY::CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_UPDATED_SUCCESS_TITLE
        end

        it "can submit form with Regional Office and notes" do
          click_dropdown({ text: "Atlanta, GA" }, find(".cf-modal-body"))
          fill_in("Notes", with: instructions_text)

          click_button("Confirm")

          expect(page)
            .to have_content COPY::CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_UPDATED_SUCCESS_TITLE
        end
      end
    end

    context "with a regular member" do
      before do
        User.authenticate!(user: user)
      end

      it "has no actions" do
        visit("/queue/appeals/#{appeal_id}")

        expect(page).to have_content("Verify Address")
        expect(page).not_to have_selector(".cf-select__control")
      end
    end
  end
end

RSpec.feature HearingAdminActionVerifyAddressTask, :all_dbs do
  describe "Address Verify Workflow with Legacy Appeal" do
    let!(:appeal) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case)) }
    let!(:appeal_id) { appeal.vacols_id }

    include_examples "Address Verify Task Frontend Workflow"
  end

  describe "Address Verify Workflow with AMA Appeal" do
    let!(:veteran) { create(:veteran) }
    let!(:appeal) { create(:appeal, :hearing_docket, veteran: veteran) }
    let!(:appeal_id) { appeal.uuid }

    include_examples "Address Verify Task Frontend Workflow"
  end
end
