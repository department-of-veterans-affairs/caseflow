# frozen_string_literal: true

RSpec.feature("The Correspondence Details All Tasks Actions") do
  include CorrespondenceHelpers
  include CorrespondenceTaskHelpers
  include CorrespondenceTaskActionsHelpers

  let!(:organizations) do
    organizations_array_list.map { |name| create(:organization, name: name) }
  end
  let(:privacy_user) { create(:user, css_id: "PRIVACY_TEAM_USER", full_name: "Leighton PrivacyAndFOIAUser Naumov") }
  let(:current_user) { create(:user) }
  let(:cavc_user) { create(:user, css_id: "CAVC_LIT_SUPPORT_ADMIN", full_name: "CAVCLitSupportAdmin") }
  let(:liti_user) { create(:user, css_id: "LITIGATION_SUPPORT_ADMIN", full_name: "LITIGATIONSUPPORT") }
  let(:colocated_user) { create(:user, css_id: "COLOCATED_ADMIN", full_name: "ColocatedAdmin") }
  let(:hearings_user) { create(:user, css_id: "HEARINGS_ADMIN", full_name: "HearingsAdmin") }
  let(:user_team) { InboundOpsTeam.singleton }
  let(:privacy_team) { PrivacyTeam.singleton }
  let(:cavc_team) { CavcLitigationSupport.singleton }
  let(:liti_team) { LitigationSupport.singleton }
  let(:colocated_team) { Colocated.singleton }
  let(:hearings_team) { HearingAdmin.singleton }
  let!(:veteran) { create(:veteran, first_name: "John", last_name: "Testingman", file_number: "8675309") }
  let!(:correspondence) { create(:correspondence, :completed, veteran: veteran) }

  context "testing tasks actions" do
    CorrespondenceTaskActionsHelpers::TASKS.each do |task_action|
      context "for #{task_action[:name]} tasks" do
        before do
          send("correspondence_spec_#{task_action[:access_type]}")
          FeatureToggle.enable!(:correspondence_queue)
          @correspondence = create(
            :correspondence,
            :completed,
            veteran: veteran,
            va_date_of_receipt: Time.zone.now,
            nod: false,
            notes: "Notes for #{task_action[:name]}"
          )
        end

        before :each do
          setup_correspondence_task(
            correspondence: @correspondence,
            task_class: task_action[:class],
            assigned_to_type: task_action[:assigned_to_type],
            assigned_to: send(task_action[:assigned_to]),
            instructions: "#{task_action[:name]} Instructions"
          )
        end

        it "checks that #{task_action[:name]} task can be cancelled." do
          check_task_action(
            correspondence: @correspondence,
            task_name: task_action[:name],
            action: "Cancel task",
            button_id: "Cancel-task-button-id-1",
            expected_message: "task has been cancelled." \
                              " If you have made a mistake, please email #{task_action[:team_name]} for any changes.",
            form_text: "Cancel task test"
          )
        end

        it "checks that #{task_action[:name]} task can be completed." do
          check_task_action(
            correspondence: @correspondence,
            task_name: task_action[:name],
            action: "Mark task complete",
            button_id: "Mark-as-complete-button-id-1",
            expected_message: "task has been marked complete." \
                              " If you have made a mistake, please email #{task_action[:team_name]} for any changes.",
            form_text: "Complete task test"
          )
        end

        it "Verify #{task_action[:name]} task with Assign to team action dropdown" do
          visit "/queue/correspondence/#{@correspondence.uuid}"
          # find + dropdowns and click last one for tasks unrelated to appeal
          dropdowns = page.all(".toggleButton-plus-or-minus")
          dropdowns.last.click
          click_dropdown(prompt: "Select an action", text: "Assign to team")
          expect(page).to have_content("Assign task")
          expect(page).to have_content("Select a team")
          click_dropdown(prompt: "Select or search", text: "Education")
          find(".cf-form-textarea", match: :first).fill_in with: "Assign task instructions"
          click_button "Assign-task-button-id-1"
          # find + dropdowns and click last one for tasks unrelated to appeal
          dropdowns = page.all(".toggleButton-plus-or-minus")
          dropdowns.last.click
          expect(page).to have_content("#{task_action[:name]} task has been assigned to Education.")
          expect(all(".cf-row-wrapper")[1].text).to include("Education")
          expect(all(".cf-row-wrapper")[2].text).to include(task_action[:name].to_s)
          click_button("View task instructions")
          expect(all(".task-instructions")[1].text).to include("Assign task instructions")
        end

        it "Verify #{task_action[:name]} task with Change task type action dropdown" do
          visit "/queue/correspondence/#{@correspondence.uuid}"
          # find + dropdowns and click last one for tasks unrelated to appeal
          dropdowns = page.all(".toggleButton-plus-or-minus")
          dropdowns.last.click
          click_dropdown(prompt: "Select an action", text: "Change task type")
          expect(page).to have_content("Change task type")
          expect(page).to have_content("Select another task type from the list of available options:")
          click_dropdown(prompt: "Select an action type", text: "CAVC Correspondence")
          find(".cf-form-textarea", match: :first).fill_in with: "Change task type instructions"
          click_button "Change-task-type-button-id-1"
          # find + dropdowns and click last one for tasks unrelated to appeal
          dropdowns = page.all(".toggleButton-plus-or-minus")
          dropdowns.last.click
          expect(page).to have_content("You have changed the task type from #{task_action[:name]} " \
          "to CAVC Correspondence. These changes are now reflected in the tasks section below.")
          expect(all(".cf-row-wrapper")[2].find("dd").text).to eq("CAVC Correspondence")
          click_button("View task instructions")
          expect(all(".task-instructions")[1].text).to include("Change task type instructions")
        end
      end
    end
  end
end
