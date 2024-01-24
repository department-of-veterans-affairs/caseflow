# frozen_string_literal: true

RSpec.feature "Send Final Notification Letter Tasks", :all_dbs do
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

  let(:post_initial_task) do
    PostSendInitialNotificationLetterHoldingTask.create!(
      appeal: distribution_task.appeal,
      parent: distribution_task,
      end_date: Time.zone.now + days_on_hold.days,
      assigned_by: user,
      assigned_to: cob_team,
      instructions: "45 Day Hold Period"
    )
  end
  let(:post_task_timer) do
    TimedHoldTask.create_from_parent(
      post_initial_task,
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
    let(:final_letter_task) do
      SendFinalNotificationLetterTask.create!(
        appeal: root_task.appeal,
        parent: distribution_task,
        assigned_to: cob_team
      )
    end

    it "displays the proper task actions for the final letter task" do
      initial_letter_task.completed!
      post_initial_task.completed!

      visit("/queue")
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")

      # find and click action dropdown
      dropdown = find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL)
      dropdown.click
      expect(page).to have_content(Constants.TASK_ACTIONS.MARK_FINAL_NOTIFICATION_LETTER_TASK_COMPLETE.label)
      expect(page).to have_content(Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER_FINAL.label)
      expect(page).to have_content(Constants.TASK_ACTIONS.RESEND_FINAL_NOTIFICATION_LETTER.label)
      expect(page).to have_content(Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_FINAL_LETTER_TASK.label)
    end

    it "resend initial notification letter action completes the task and displays it on the case timeline" do
      initial_letter_task.completed!
      post_initial_task.completed!

      visit("/queue")
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")

      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER_FINAL.label
      click_dropdown(prompt: prompt, text: text)

      # check cancel modal content
      expect(page).to have_content(format(COPY::RESEND_INITIAL_NOTIFICATION_LETTER_FINAL_COPY))

      # fill out instructions
      fill_in("completeTaskInstructions", with: "instructions")
      click_button(format(COPY::RESEND_INITIAL_NOTIFICATION_LETTER_BUTTON))

      # navigate to queue to check case timeline
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")

      # check the screen output and model status
      appeal_final_letter_task = root_task.appeal.tasks.find_by(type: "SendFinalNotificationLetterTask")
      expect(appeal_final_letter_task.status).to eq("cancelled")
    end

    it "resend final notification letter action completes the task and displays it on the case timeline" do
      initial_letter_task.completed!
      post_initial_task.completed!

      visit("/queue")
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")

      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.RESEND_FINAL_NOTIFICATION_LETTER.label
      click_dropdown(prompt: prompt, text: text)

      # check cancel modal content
      expect(page).to have_content(format(COPY::RESEND_FINAL_NOTIFICATION_LETTER_COPY))

      # fill out instructions
      fill_in("completeTaskInstructions", with: "instructions")
      click_button(format(COPY::RESEND_FINAL_NOTIFICATION_LETTER_BUTTON))

      # navigate to queue to check case timeline
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")

      # check the screen output and model status
      appeal_final_letter_task = root_task.appeal.tasks.find_by(type: "SendFinalNotificationLetterTask")
      expect(page).to have_content(`#{appeal_final_letter_task.type} completed`)
      expect(appeal_final_letter_task.status).to eq("completed")
    end

    it "cancel action cancels the task and displays it on the case timeline" do
      initial_letter_task.completed!
      post_initial_task.completed!

      visit("/queue")
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")

      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_FINAL_LETTER_TASK.label
      click_dropdown(prompt: prompt, text: text)

      # check cancel modal content
      expect(page).to have_content(format(COPY::CANCEL_FINAL_NOTIFICATION_LETTER_TASK_DETAIL))

      # fill out instructions
      fill_in("taskInstructions", with: "instructions")
      find("#Cancel-task-button-id-1:enabled").click

      # expect success
      expect(page).to have_content(format(COPY::CANCEL_TASK_CONFIRMATION, root_task.appeal.veteran.person.name))
      expect(page.current_path).to eq("/queue")

      # navigate to queue to check case timeline
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")

      # check the screen output and model status
      appeal_initial_letter_task = root_task.appeal.tasks.find_by(type: "SendFinalNotificationLetterTask")
      expect(page).to have_content(`#{appeal_initial_letter_task.type} cancelled`)
      expect(appeal_initial_letter_task.status).to eq("cancelled")
    end
  end

  describe "Mark final notification letter task as complete" do
    let(:final_letter_task) do
      SendFinalNotificationLetterTask.create!(
        appeal: root_task.appeal,
        parent: distribution_task,
        assigned_to: cob_team
      )
    end
    let(:params) { { appeal: root_task.appeal, parent_id: root_task.id, instructions: "foo bar" } }
    subject { DocketSwitchMailTask.create_from_params(params, user) }

    it "Finalice the process, select NO in the radio bottom option" do
      initial_letter_task.completed!
      post_initial_task.completed!

      visit("/queue")
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")

      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.MARK_FINAL_NOTIFICATION_LETTER_TASK_COMPLETE.label
      click_dropdown(prompt: prompt, text: text)
      expect(page).to have_content(format(COPY::MARK_AS_COMPLETE_FROM_SEND_FINAL_NOTIFICATION_LETTER_CONTESTED_CLAIM))

      # Click radio buttom
      radio_choices = page.all(".cf-form-radio-option > label")

      expect(radio_choices[0]).to have_content("Yes")
      expect(radio_choices[1]).to have_content("No")

      radio_choices[1].click
      click_button("Mark as complete")

      visit("/queue")
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")
      expect(page).to have_content("SendFinalNotificationLetterTask completed")

    end
    it "Finalice the process, select Yes in the radio bottom option" do
      initial_letter_task.completed!
      post_initial_task.completed!

      visit("/queue")
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")

      prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      text = Constants.TASK_ACTIONS.MARK_FINAL_NOTIFICATION_LETTER_TASK_COMPLETE.label
      click_dropdown(prompt: prompt, text: text)
      expect(page).to have_content(format(COPY::MARK_AS_COMPLETE_FROM_SEND_FINAL_NOTIFICATION_LETTER_CONTESTED_CLAIM))

      # Click radio buttom
      radio_choices = page.all(".cf-form-radio-option > label")

      expect(radio_choices[0]).to have_content("Yes")
      expect(radio_choices[1]).to have_content("No")

      radio_choices[0].click
      fill_in("instructions", with: "Mark as complete for instructions")
      click_button("Mark as complete")

      subject
      visit("/queue")
      visit("/queue/appeals/#{final_letter_task.appeal.external_id}")

      expect(page).to have_content("SendFinalNotificationLetterTask completed")
      expect(page).to have_content("Docket Switch")
    end

  end
end
