# frozen_string_literal: true

RSpec.feature "Send Post Initial Notification Letter Holding Tasks", :all_dbs do
  let(:user) { create(:user) }
  let(:cob_team) { ClerkOfTheBoard.singleton }

  let(:root_task) { create(:root_task) }
  let(:distribution_task) { create(:distribution_task, parent: root_task) }
  let(:days_on_hold) { 45 }
  let(:initial_letter_task) do
    SendInitialNotificationLetterTask.create!(
      appeal: root_task.appeal,
      parent: distribution_task,
      assigned_to: cob_team
    )
  end

  let(:post_letter_task) do
    PostSendInitialNotificationLetterHoldingTask.create!(
      appeal: root_task.appeal,
      parent: distribution_task,
      assigned_to: cob_team,
      assigned_by: user,
      end_date: Time.zone.now + days_on_hold.days
    )
  end

  let(:post_task_timer) do
    TimedHoldTask.create_from_parent(
      post_letter_task,
      days_on_hold: days_on_hold,
      instructions: "45 Days Hold Period"
    )
  end

  before do
    cob_team.add_user(user)
    User.authenticate!(user: user)
    FeatureToggle.enable!(:cc_appeal_workflow)
  end

  describe "Accessing task actions" do
    it "displays the proper task actions for the final letter task" do
      initial_letter_task.completed!

      visit("/queue")
      visit("/queue/appeals/#{post_letter_task.appeal.external_id}")

      # find and click action dropdown
      dropdown = find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL)
      dropdown.click
      expect(page).to have_content(Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_POST_INITIAL_LETTER_TASK.label)
      expect(page).to have_content(Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER_POST_HOLDING.label)
      expect(page).to have_content(Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_POST_HOLDING.label)
    end

    it "resend initial notification action creates initial notification task and completes the post initial notification holding task" do
      initial_letter_task.completed!
      visit("/queue")
      visit("/queue/appeals/#{post_letter_task.appeal.external_id}")

      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER_POST_HOLDING.label
      click_dropdown(prompt: prompt, text: text)

      # check modal content
      expect(page).to have_content(format(COPY::RESEND_INITIAL_NOTIFICATION_LETTER_POST_HOLDING_COPY))

      # fill out instructions
      fill_in("instructions", with: "instructions")
      click_button(COPY::RESEND_INITIAL_NOTIFICATION_LETTER_BUTTON)

      # expect success
      assert page.has_content?("Post Send Initial Notification Letter Holding task completed")
      expect(page.current_path).to eq("/organizations/clerk-of-the-board")
      appeal_initial_letter_holding_task = root_task.appeal.tasks.reload.find_by(type: "PostSendInitialNotificationLetterHoldingTask")
      expect(appeal_initial_letter_holding_task.status).to eq("completed")
    end

    it "cancel action cancels the task and displays it on the case timeline" do
      initial_letter_task.completed!

      visit("/queue")
      visit("/queue/appeals/#{post_letter_task.appeal.external_id}")

      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_POST_INITIAL_LETTER_TASK.label
      click_dropdown(prompt: prompt, text: text)

      # check cancel modal content
      expect(page).to have_content(format(COPY::CANCEL_POST_INITIAL_NOTIFICATION_LETTER_TASK_DETAIL))

      # fill out instructions
      fill_in("taskInstructions", with: "instructions go here")
      find("#Cancel-task-button-id-1:enabled").click
      # expect success
      expect(page).to have_content(format(COPY::CANCEL_TASK_CONFIRMATION, root_task.appeal.veteran.person.name))
      expect(page.current_path).to eq("/queue")

      # navigate to queue to check case timeline
      visit("/queue/appeals/#{post_letter_task.appeal.external_id}")

      # check the screen output and model status
      appeal_initial_letter_task = root_task.appeal.tasks.find_by(type: "PostSendInitialNotificationLetterHoldingTask")
      expect(page).to have_content(`#{appeal_initial_letter_task.type} cancelled`)
      expect(appeal_initial_letter_task.status).to eq("cancelled")
    end

    it "the proceed to final letter action completes the post initial task" do
      initial_letter_task.completed!
      visit("/queue")
      visit("/queue/appeals/#{post_letter_task.appeal.external_id}")

      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_POST_HOLDING.label
      click_dropdown(prompt: prompt, text: text)

      # check modal content
      expect(page).to have_content(format(COPY::PROCEED_FINAL_NOTIFICATION_LETTER_TITLE))

      # fill out instructions
      fill_in("instructions", with: "instructions")
      click_button(COPY::PROCEED_FINAL_NOTIFICATION_LETTER_BUTTON)

      # expect success
      expect(page).to have_content(format(COPY::PROCEED_FINAL_NOTIFICATION_LETTER_POST_HOLDING_TASK_SUCCESS))
      expect(page.current_path).to eq("/organizations/clerk-of-the-board")
      appeal_initial_letter_holding_task = root_task.appeal.tasks.reload.find_by(type: "PostSendInitialNotificationLetterHoldingTask")
      expect(appeal_initial_letter_holding_task.status).to eq("completed")
    end
  end
end
