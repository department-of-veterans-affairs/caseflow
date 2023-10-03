# frozen_string_literal: true

RSpec.feature "ColocatedTask", :all_dbs do
  let!(:vlj_support_staff) { create(:user, :vlj_support_user) }
  let(:vlj_admin) do
    user = create(:user)
    OrganizationsUser.make_user_admin(user, Colocated.singleton)
    user
  end

  describe "attorney assigns task to vlj support staff, vlj returns it to attorney after completion" do
    let(:judge_user) { create(:user) }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
    let(:attorney_user) { create(:user) }
    let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }
    let(:root_task) { create(:root_task) }
    let(:judge_task) { create(:ama_judge_decision_review_task, assigned_to: judge_user, parent: root_task) }
    let(:appeal) { root_task.appeal }
    let!(:atty_task) do
      create(
        :ama_attorney_task,
        parent: judge_task,
        assigned_by: judge_user,
        assigned_to: attorney_user
      )
    end
    let(:return_instructions) { "These are the instructions from the VLJ" }

    it "should return attorney task to active state" do
      # Attorney assigns task to VLJ support staff.
      User.authenticate!(user: attorney_user)
      visit("/queue") # this otherwise flakes
      visit("/queue/appeals/#{appeal.uuid}")

      find(".cf-select__control", text: "Select an action…").click
      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h[:label]).click

      # Redirected to assign colocated action page
      action = Constants.CO_LOCATED_ADMIN_ACTIONS.poa_clarification
      find(".cf-select__control", text: "Select an action").click
      find("div", class: "cf-select__option", text: action).click
      fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "note")
      find("button", text: COPY::ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL).click

      # Redirected to personal queue page. Assignment succeeds.
      expect(page).to have_content("You have assigned an administrative action (#{action})")

      # Log in as a VLJ admin user and assign it to vlj_support_staff user
      User.authenticate!(user: vlj_admin)
      visit("/organizations/vlj-support")
      find("button", text: "Assign Tasks").click
      find(".cf-form-dropdown", text: "Assign to").click
      find("option", text: "#{vlj_support_staff.css_id} #{vlj_support_staff.full_name}").click
      find(".cf-form-dropdown", text: "Select task type").click
      find("option", text: "Poa Clarification Colocated Task").click
      find(".cf-form-dropdown", text: "Select number of tasks to assign").click
      find("option", text: "1 (all available tasks)").click
      find("button", id: "Bulk-Assign-Tasks-button-id-1").click # going by text is an ambiguous match
      expect(page).to have_content("You have bulk assigned 1 Poa Clarification Colocated Task tasks")

      # Visit case details page for VLJ support staff.
      User.authenticate!(user: vlj_support_staff)
      visit("/queue/appeals/#{appeal.uuid}")
      # Return case to attorney.
      find(".cf-select__control", text: "Select an action…").click
      find(
        "div",
        class: "cf-select__option",
        text: Constants.TASK_ACTIONS.COLOCATED_RETURN_TO_ATTORNEY.to_h[:label]
      ).click
      fill_in("instructions", with: return_instructions)
      find("button", text: COPY::MARK_TASK_COMPLETE_BUTTON).click

      # Redirected to personal queue page. Return to attorney succeeds.
      expect(page).to have_content(
        format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, appeal.veteran.name.formatted(:readable_full))
      )

      # View attorney personal queue page. Should see appeal in assigned active queue.
      User.authenticate!(user: attorney_user)
      visit("/queue")

      # Click into case details page.
      click_on(appeal.veteran.name.formatted(:readable_full))
      # verify that the instructions from the VLJ appear on the case timeline
      expect(page).to have_css("h2", text: "Case Timeline")
      scroll_to(find("h2", text: "Case Timeline"))
      poa_task = PoaClarificationColocatedTask.last
      click_button(text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL, id: poa_task.id)
      expect(page).to have_content(return_instructions)
      # Expect to see draft decision option.
      find(".cf-select__control", text: "Select an action…").click
      expect(page).to have_content(Constants.TASK_ACTIONS.REVIEW_AMA_DECISION.to_h[:label])

      # ColocatedTask assigned to organization should have status completed.
      expect(atty_task.children.first.status).to eq(Constants.TASK_STATUSES.completed)
    end
  end

  describe "vlj support staff places the task on hold" do
    let(:root_task) { create(:root_task) }
    let(:appeal) { root_task.appeal }
    let(:veteran_name) { appeal.veteran.name.formatted(:readable_full) }

    context "when ColocatedTask is in progress" do
      let(:hold_duration_days) { 15 }
      let!(:colocated_task) do
        create(
          :ama_colocated_task,
          appeal: appeal,
          parent: root_task
        )
      end
      let!(:individual_task) do
        create(:ama_colocated_task, appeal: appeal, parent: colocated_task, assigned_to: vlj_support_staff)
      end

      it "is successfully placed on hold" do
        # Visit case details page for VLJ support staff.
        User.authenticate!(user: vlj_support_staff)
        visit("/queue/appeals/#{appeal.uuid}")

        # Attempt to put the task on hold.
        click_dropdown(text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)

        # Modal appears.
        expect(page).to have_content(Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)

        # Attempt to place the task on hold without including notes.
        find(".cf-select__control", text: COPY::COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL).click
        find("div", class: "cf-select__option", text: "#{hold_duration_days} days").click
        click_on(COPY::MODAL_PUT_TASK_ON_HOLD_BUTTON)

        # Notes field is required
        expect(page).to have_content(COPY::NOTES_ERROR_FIELD_REQUIRED)

        # Add instructions and try again
        fill_in("instructions", with: "some text")
        click_on(COPY::MODAL_PUT_TASK_ON_HOLD_BUTTON)

        # We should see a success message and remain on the case details page.
        expect(page).to have_content(
          format(COPY::COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, veteran_name, hold_duration_days)
        )
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        # Task snapshot updated with new hold information
        expect(page).to have_content("0 of #{hold_duration_days}")
      end
    end
  end

  describe "vlj support staff changes task type" do
    let(:root_task) { create(:root_task) }
    let(:appeal) { root_task.appeal }
    let!(:colocated_task) do
      create(
        :ama_colocated_task,
        :other,
        appeal: appeal,
        parent: root_task,
        assigned_to: vlj_support_staff
      )
    end

    let(:new_task_type) { IhpColocatedTask }

    it "should update the task type" do
      # Visit case details page for VLJ support staff.
      User.authenticate!(user: vlj_support_staff)
      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

      # Navigate to the change task type modal
      find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h[:label]).click

      expect(page).to have_content(COPY::CHANGE_TASK_TYPE_SUBHEAD)

      # Ensure all admin actions are available
      find(".cf-select__control", text: "Select an action type").click do
        visible_options = page.find_all(".cf-select__option")
        expect(visible_options.length).to eq Constants::CO_LOCATED_ADMIN_ACTIONS.length
      end

      # Attempt to change task type without including instuctions.
      find("div", class: "cf-select__option", text: new_task_type.label).click
      find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

      # Instructions field is required
      expect(page).to have_content(COPY::INSTRUCTIONS_ERROR_FIELD_REQUIRED)

      # Add instructions and try again
      instructions = generate_words(5)
      fill_in("instructions", with: instructions)
      find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

      # We should see a success message but remain on the case details page
      expect(page).to have_content(
        format(
          COPY::CHANGE_TASK_TYPE_CONFIRMATION_TITLE,
          Constants::CO_LOCATED_ADMIN_ACTIONS.values.last,
          new_task_type.label
        )
      )

      # Ensure the task has been updated
      expect(page).to have_content(format("TASK\n%<label>s", label: new_task_type.label))
      page.find("#currently-active-tasks button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
      expect(page).to have_content(instructions)
    end
  end
end
