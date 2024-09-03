# frozen_string_literal: true

RSpec.feature("The Correspondence Details Other Motions Tasks Actions") do
  include CorrespondenceHelpers
  include CorrespondenceTaskHelpers

  let!(:organizations) do
    organizations_array_list.map { |name| create(:organization, name: name) }
  end
  let(:current_user) { create(:user) }
  let!(:veteran) { create(:veteran, first_name: "John", last_name: "Testingman", file_number: "8675309") }
  let!(:correspondence) { create(:correspondence, veteran: veteran) }

  context "testing for other motion dropdowns" do
    before do
      correspondence_spec_user_access
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence = create(
        :correspondence,
        veteran: veteran,
        va_date_of_receipt: "Wed, 24 Jul 2024 00:00:00 EDT -04:00",
        nod: false,
        notes: "Notes for Other Motion"
      )
    end

    before :each do
      task = OtherMotionCorrespondenceTask.create!(
        parent: @correspondence.tasks[0],
        appeal: @correspondence,
        appeal_type: "Correspondence",
        status: "assigned",
        assigned_to_type: "User",
        assigned_to: current_user,
        instructions: ["Other Motion"],
        assigned_at: Time.current
      )
      Organization.assignable(task)
      @organizations = task.reassign_organizations.map { |org| { label: org.name, value: org.id } }
    end

    it "checks that Other Motion task can be cancelled." do
      visit "/queue/correspondence/#{@correspondence.uuid}"
      click_dropdown(prompt: "Select an action", text: "Cancel task")
      find(".cf-form-textarea", match: :first).fill_in with: "Cancel task test"
      click_button "Cancel-task-button-id-1"
      expect(page).to have_content("Other Motion task has been cancelled.")
    end

    it "checks that Other Motion task can be completed." do
      visit "/queue/correspondence/#{@correspondence.uuid}"
      click_dropdown(prompt: "Select an action", text: "Mark task complete")
      find(".cf-form-textarea", match: :first).fill_in with: "Complete task test"
      click_button "Mark-as-complete-button-id-1"
      expect(page).to have_content("Other motion task has been marked complete.")
    end

    it "Verify Other Motion task with Assign to team action dropdown" do
      visit "/queue/correspondence/#{@correspondence.uuid}"
      click_dropdown(prompt: "Select an action", text: "Assign to team")
      expect(page).to have_content("Assign Task")
      expect(page).to have_content("Select a team")
      click_dropdown(prompt: "Select or search", text: "Education")
      find(".cf-form-textarea", match: :first).fill_in with: "Assign task instructions"
      click_button "Assign-Task-button-id-1"
      expect(page).to have_content("Other motion task has been assigned to Education.")
      expect(all(".cf-row-wrapper")[1].text).to include("Education")
      expect(all(".cf-row-wrapper")[2].text).to include("Other motion")
      click_button("View task instructions")
      expect(all(".task-instructions")[1].text).to include("Assign task instructions")
    end

    it "Verify Other Motion task with Change task type action dropdown" do
      visit "/queue/correspondence/#{@correspondence.uuid}"
      click_dropdown(prompt: "Select an action", text: "Change task type")
      expect(page).to have_content("Change task type")
      expect(page).to have_content("Select another task type from the list of available options:")
      click_dropdown(prompt: "Select an action type", text: "CAVC Correspondence")
      find(".cf-form-textarea", match: :first).fill_in with: "Change task type instructions"
      click_button "Change-task-type-button-id-1"
      expect(page).to have_content("You have changed the task type from Other motion to CAVC Correspondence. " \
      "These changes are now reflected in the tasks section below.")
      expect(all(".cf-row-wrapper")[2].find("dd").text).to eq("CAVC Correspondence")
      click_button("View task instructions")
      expect(all(".task-instructions")[1].text).to include("Change task type instructions")
    end
  end
end
