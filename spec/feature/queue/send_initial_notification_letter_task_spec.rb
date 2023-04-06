# frozen_string_literal: true

RSpec.feature "Send Initial Notification Letter Tasks", :all_dbs do
  let(:user) { create(:user) }
  let(:cob_team) { ClerkOfTheBoard.singleton }

  before do
    cob_team.add_user(user)
    User.authenticate!(user: user)
    FeatureToggle.enable!(:cc_appeal_workflow)
  end

  describe "Accessing task actions" do
    let(:root_task) { create(:root_task) }
    let(:distribution_task) { create(:distribution_task, parent: root_task) }
    let(:initial_letter_task) do
      SendInitialNotificationLetterTask.create!(
        appeal: root_task.appeal,
        parent: distribution_task,
        assigned_to: cob_team
      )
    end

    it "displays the proper task actions for the intial task" do
      visit("/queue")
      visit("/queue/appeals/#{initial_letter_task.appeal.external_id}")
      # find and click action dropdown
      dropdown = find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL)
      dropdown.click
      expect(page).to have_content(Constants.TASK_ACTIONS.MARK_TASK_AS_COMPLETE_CONTESTED_CLAIM.label)
      expect(page).to have_content(Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_INITIAL.label)
      expect(page).to have_content(Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_INITIAL_LETTER_TASK.label)
    end

    it "mark task complete action completes the task" do
      visit("/queue")
      visit("/queue/appeals/#{initial_letter_task.appeal.external_id}")
      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.MARK_TASK_AS_COMPLETE_CONTESTED_CLAIM.label
      click_dropdown(prompt: prompt, text: text)

      # check modal content
      expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_TITLE_CONTESTED_CLAIM))
      expect(page).to have_content(format(COPY::MARK_AS_COMPLETE_CONTESTED_CLAIM_DETAIL))

      # click 45 days from the options
      find("label", text: "45 days").click

      # submit form
      click_button(COPY::MARK_TASK_COMPLETE_BUTTON_CONTESTED_CLAIM)

      # expect success
      expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, root_task.appeal.veteran.person.name))
      expect(page.current_path).to eq("/organizations/clerk-of-the-board")
      appeal_initial_letter_task = root_task.appeal.tasks.reload.find_by(type: "SendInitialNotificationLetterTask")
      expect(appeal_initial_letter_task.status).to eq("completed")
    end

    it "proceed to final notification action creates final notification task and completes the initial notification task" do
      visit("/queue")
      visit("/queue/appeals/#{initial_letter_task.appeal.external_id}")
      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_INITIAL.label
      click_dropdown(prompt: prompt, text: text)

      # check modal content
      expect(page).to have_content(format(COPY::PROCEED_FINAL_NOTIFICATION_LETTER_INITIAL_COPY))

      # fill out instructions
      fill_in("instructions", with: "instructions")
      click_button(COPY::PROCEED_FINAL_NOTIFICATION_LETTER_BUTTON)

      # expect success
      assert page.has_content?("Send Initial Notification Letter task completed")
      expect(page.current_path).to eq("/organizations/clerk-of-the-board")
      appeal_initial_letter_task = root_task.appeal.tasks.reload.find_by(type: "SendInitialNotificationLetterTask")
      expect(appeal_initial_letter_task.status).to eq("completed")
    end

    it "cancel action cancels the task and displays it on the case timeline" do
      visit("/queue")
      visit("/queue/appeals/#{initial_letter_task.appeal.external_id}")

      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_INITIAL_LETTER_TASK.label
      click_dropdown(prompt: prompt, text: text)

      # check cancel modal content
      expect(page).to have_content(format(COPY::CANCEL_INITIAL_NOTIFICATION_LETTER_TASK_DETAIL))

      # fill out instructions
      fill_in("taskInstructions", with: "instructions")
      find("#Cancel-task-button-id-1:enabled").click

      # expect success
      expect(page).to have_content(format(COPY::CANCEL_TASK_CONFIRMATION, root_task.appeal.veteran.person.name))
      expect(page.current_path).to eq("/queue")

      # navigate to queue to check case timeline
      visit("/queue/appeals/#{initial_letter_task.appeal.external_id}")

      # check the screen output and model status
      appeal_initial_letter_task = root_task.appeal.tasks.find_by(type: "SendInitialNotificationLetterTask")
      expect(page).to have_content(`#{appeal_initial_letter_task.type} cancelled`)
      expect(appeal_initial_letter_task.status).to eq("cancelled")
    end
  end
end
