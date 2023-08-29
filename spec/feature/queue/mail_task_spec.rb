# frozen_string_literal: true

RSpec.feature "MailTasks", :postgres do
  let(:user) { create(:user) }

  before do
    User.authenticate!(user: user)
  end

  describe "Assigning a mail team task to a team member" do
    context "when task is assigned to AOD team" do
      let(:root_task) { create(:root_task) }

      let(:mail_team_task) do
        AodMotionMailTask.create!(
          appeal: root_task.appeal,
          parent_id: root_task.id,
          assigned_to: MailTeam.singleton
        )
      end

      let(:aod_team) { AodTeam.singleton }

      let(:aod_team_task) do
        AodMotionMailTask.create!(
          appeal: root_task.appeal,
          parent_id: mail_team_task.id,
          assigned_to: aod_team
        )
      end

      before do
        aod_team.add_user(user)
      end

      it "successfully assigns the task to team member" do
        visit("/queue")
        visit("queue/appeals/#{aod_team_task.appeal.external_id}")

        prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
        text = Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label
        click_dropdown(prompt: prompt, text: text)
        fill_in("taskInstructions", with: "instructions")
        click_button("Assign")

        expect(page).to have_content(format(COPY::ASSIGN_TASK_SUCCESS_MESSAGE, user.full_name))
        expect(page.current_path).to eq("/queue")

        new_tasks = aod_team_task.children
        expect(new_tasks.length).to eq(1)

        new_task = new_tasks.first
        expect(new_task.assigned_to).to eq(user)
      end
    end
  end

  describe "Changing a mail team task type" do
    let(:root_task) { create(:root_task) }
    let(:old_task_type) { DeathCertificateMailTask }
    let(:new_task_type) { AddressChangeMailTask }
    let(:old_instructions) { generate_words(5) }

    let(:grandparent_task) do
      old_task_type.create!(
        appeal: root_task.appeal,
        parent_id: root_task.id,
        assigned_to: MailTeam.singleton
      )
    end

    let(:parent_task) do
      old_task_type.create!(
        appeal: grandparent_task.appeal,
        parent_id: grandparent_task.id,
        assigned_to: Colocated.singleton,
        instructions: [old_instructions]
      )
    end

    let(:vlj_support_user) { create(:user, :vlj_support_user) }

    let(:task) do
      old_task_type.create!(
        appeal: parent_task.appeal,
        parent_id: parent_task.id,
        assigned_to: vlj_support_user,
        status: Constants.TASK_STATUSES.assigned,
        instructions: [old_instructions]
      )
    end

    before do
      Colocated.singleton.add_user(user)
    end

    it "should update the task type" do
      visit "/queue/" # avoids a weird race condition
      visit "/queue/appeals/#{task.appeal.uuid}"

      # Make sure mail team tasks do not show in task snapshot
      expect(find("#currently-active-tasks").has_no_content?("ASSIGNED TO\nMail")).to eq(true)
      expect(find_all("#currently-active-tasks tr").length).to eq 1

      # Navigate to the change task type modal
      find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h[:label]).click

      expect(page).to have_content(COPY::CHANGE_TASK_TYPE_SUBHEAD)

      # Ensure all admin actions are available
      mail_tasks = MailTask.subclass_routing_options
      find(".cf-select__control", text: "Select an action type").click do
        visible_options = page.find_all(".cf-select__option")
        expect(visible_options.length).to eq mail_tasks.length
      end

      # Attempt to change task type without including instuctions.
      find("div", class: "cf-select__option", text: new_task_type.label).click
      find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

      # Instructions field is required
      expect(page).to have_content(COPY::INSTRUCTIONS_ERROR_FIELD_REQUIRED)

      # Add instructions and try again
      new_instructions = generate_words(5)
      fill_in("instructions", with: new_instructions)
      find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

      # We should see a success message but remain on the case details page
      expect(page).to have_content(
        format(
          COPY::CHANGE_TASK_TYPE_CONFIRMATION_TITLE,
          old_task_type.label,
          new_task_type.label
        )
      )

      # Ensure the task has been updated and the assignee is unchanged
      expect(page).to have_content(format("TASK\n%<label>s", label: new_task_type.label))
      expect(page).to have_content(format("ASSIGNED TO\nVLJ Support Staff"))
      page.find("#currently-active-tasks button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
      expect(page).to have_content(old_instructions)
      expect(page).to have_content(new_instructions)
    end
  end
end
