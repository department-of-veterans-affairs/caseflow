# frozen_string_literal: true

require "rails_helper"

RSpec.feature "ColocatedTask" do
  let(:vlj_support_staff) { FactoryBot.create(:user) }

  before { OrganizationsUser.add_user_to_organization(vlj_support_staff, Colocated.singleton) }

  describe "attorney assigns task to vlj support staff, vlj returns it to attorney after completion" do
    let(:judge_user) { FactoryBot.create(:user) }
    let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, sdomainid: judge_user.css_id) }

    let(:attorney_user) { FactoryBot.create(:user) }
    let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

    let(:root_task) { FactoryBot.create(:root_task) }
    let(:appeal) { root_task.appeal }

    let!(:atty_task) do
      FactoryBot.create(
        :ama_attorney_task,
        appeal: appeal,
        parent: root_task,
        assigned_by: judge_user,
        assigned_to: attorney_user
      )
    end

    it "should return attorney task to active state" do
      # Attorney assigns task to VLJ support staff.
      User.authenticate!(user: attorney_user)
      visit("/queue/appeals/#{appeal.uuid}")

      find(".Select-control", text: "Select an action…").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h[:label]).click

      # Redirected to assign colocated action page
      action = Constants.CO_LOCATED_ADMIN_ACTIONS.poa_clarification
      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: action).click
      fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "note")
      find("button", text: COPY::ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL).click

      # Redirected to personal queue page. Assignment succeeds.
      expect(page).to have_content("You have assigned an administrative action (#{action})")

      # Visit case details page for VLJ support staff.
      User.authenticate!(user: vlj_support_staff)
      visit("/queue/appeals/#{appeal.uuid}")

      # Return case to attorney.
      find(".Select-control", text: "Select an action…").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.COLOCATED_RETURN_TO_ATTORNEY.to_h[:label]).click
      fill_in("instructions", with: "INSTRUCTIONS FROM VLJ")
      find("button", text: COPY::MARK_TASK_COMPLETE_BUTTON).click

      # Redirected to personal queue page. Return to attorney succeeds.
      expect(page).to have_content(
        format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, appeal.veteran.name.formatted(:readable_full))
      )

      # View attorney personal queue page. Should see appeal in assigned active queue.
      User.authenticate!(user: attorney_user)
      visit("/queue")

      # Click into case details page. Expect to see draft decision option.
      click_on(appeal.veteran.name.formatted(:readable_full))
      # verify that the instructions from the VLJ appear on the case timeline
      scroll_to("#case_timeline-section")
      view_text = COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
      page.find_all("table#case-timeline-table button", text: view_text).each(&:click)
      expect(page).to have_content(
        "INSTRUCTIONS FROM VLJ"
      )
      find(".Select-control", text: "Select an action…").click
      expect(page).to have_content(Constants.TASK_ACTIONS.REVIEW_AMA_DECISION.to_h[:label])

      # ColocatedTask assigned to organization should have status completed.
      expect(atty_task.children.first.status).to eq(Constants.TASK_STATUSES.completed)
    end
  end

  describe "vlj support staff places the task on hold" do
    let(:root_task) { FactoryBot.create(:root_task) }
    let(:appeal) { root_task.appeal }
    let!(:colocated_task) do
      FactoryBot.create(
        :ama_colocated_task,
        appeal: appeal,
        parent: root_task,
        assigned_to: vlj_support_staff
      )
    end

    let(:veteran_name) { appeal.veteran.name.formatted(:readable_full) }

    it "should return attorney task to active state" do
      # Visit case details page for VLJ support staff.
      User.authenticate!(user: vlj_support_staff)
      visit("/queue/appeals/#{appeal.uuid}")

      # Attempt to put the task on hold.
      find(".Select-control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.PLACE_HOLD.to_h[:label]).click

      # Redirected to place task on hold page.
      expect(page).to have_content(
        format(COPY::COLOCATED_ACTION_PLACE_HOLD_HEAD, veteran_name, appeal.veteran.file_number)
      )

      # Attempt to place the task on hold without including notes.
      find(".Select-control", text: COPY::COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL).click
      find("div", class: "Select-option", text: "15 days").click
      find("button", text: COPY::COLOCATED_ACTION_PLACE_HOLD_BUTTON_COPY).click

      # Instructions field is required
      expect(page).to have_content(COPY::FORM_ERROR_FIELD_REQUIRED)

      # Add instructions and try again
      fill_in("instructions", with: "some text")
      find("button", text: COPY::COLOCATED_ACTION_PLACE_HOLD_BUTTON_COPY).click

      # We should see a success message and be redirected to our queue page.
      expect(page).to have_content(format(COPY::COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, veteran_name, "15"))
      expect(page).to have_current_path("/queue")
    end
  end

  describe "translation task for AMA appeal" do
    let(:action) { "translation" }
    let(:root_task) { FactoryBot.create(:root_task) }
    let(:appeal) { root_task.appeal }
    let!(:colocated_task) do
      FactoryBot.create(
        :ama_colocated_task,
        appeal: appeal,
        parent: root_task,
        assigned_to: vlj_support_staff,
        action: action
      )
    end

    before do
      # Allow the current user to access the Translation team queue to confirm that the task made it into their queue.
      OrganizationsUser.add_user_to_organization(vlj_support_staff, Translation.singleton)
    end

    it "should be able to be sent to the translation team" do
      # Visit case details page for VLJ support staff.
      User.authenticate!(user: vlj_support_staff)
      visit("/queue/appeals/#{appeal.uuid}")

      # Send case to Translation team.
      expect(TranslationTask.count).to eq 0
      find(".Select-control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.SEND_TO_TRANSLATION.label).click
      fill_in("instructions", with: "Please translate some documents")
      find("button", text: "Submit").click

      # Redirected to personal queue page. Return to attorney succeeds.
      expect(page).to have_current_path("/queue")
      expect(page).to have_content(format(COPY::ASSIGN_TASK_SUCCESS_MESSAGE, Translation.singleton.name))
      expect(TranslationTask.count).to eq 1

      # View Translation team queue to confirm the appeal shows up there.
      visit(Translation.singleton.path)
      expect(page).to have_content(appeal.veteran.name.formatted(:readable_full))
    end
  end

  describe "vlj support staff changes task type" do
    let(:root_task) { FactoryBot.create(:root_task) }
    let(:appeal) { root_task.appeal }
    let!(:colocated_task) do
      FactoryBot.create(
        :ama_colocated_task,
        appeal: appeal,
        parent: root_task,
        assigned_to: vlj_support_staff,
        action: Constants::CO_LOCATED_ADMIN_ACTIONS.keys.last
      )
    end

    # Fake available actions to allow change task type until the backend is implemented
    # https://github.com/department-of-veterans-affairs/caseflow/pull/10693
    before do
      allow_any_instance_of(ColocatedTask).to receive(:available_actions).and_return(
        [Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h]
      )
    end

    it "should update the task type" do
      # Visit case details page for VLJ support staff.
      User.authenticate!(user: vlj_support_staff)
      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

      # Navigate to the change task type modal
      find(".Select-control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h[:label]).click

      expect(page).to have_content(COPY::CHANGE_TASK_TYPE_SUBHEAD)
      opt_idx = rand(Constants::CO_LOCATED_ADMIN_ACTIONS.length - 1)
      selected_opt_0 = Constants::CO_LOCATED_ADMIN_ACTIONS.values[opt_idx]

      # Ensure all admin actions are available
      find(".Select-control", text: "Select an action type").click do
        visible_options = page.find_all(".Select-option")
        expect(visible_options.length).to eq Constants::CO_LOCATED_ADMIN_ACTIONS.length
      end

      # Attempt to change task type without including instuctions.
      find("div", class: "Select-option", text: selected_opt_0).click
      find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

      # Instructions field is required
      expect(page).to have_content(COPY::FORM_ERROR_FIELD_REQUIRED)

      # Add instructions and try again
      instructions = generate_words(5)
      fill_in("instructions", with: instructions)

      # Fake response until the backend is implemented
      # https://github.com/department-of-veterans-affairs/caseflow/pull/10693
      allow_any_instance_of(TasksController).to receive(:update).and_return(
        colocated_task.update(action: selected_opt_0, instructions: [instructions])
      )

      find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

      # We should see a success message but remain on the case details page
      expect(page).to have_content(
        format(
          COPY::CHANGE_TASK_TYPE_CONFIRMATION_TITLE,
          Constants::CO_LOCATED_ADMIN_ACTIONS.values.last,
          selected_opt_0
        )
      )

      # Ensure the task has been updated
      expect(page).to have_content(format("TASK\n%<label>s", label: selected_opt_0))
      click_on COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
      expect(page).to have_content(instructions)
    end
  end
end
