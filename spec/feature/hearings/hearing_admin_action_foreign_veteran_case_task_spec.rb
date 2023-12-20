# frozen_string_literal: true

RSpec.feature HearingAdminActionForeignVeteranCaseTask, :postgres do
  let!(:veteran) { create(:veteran) }
  let!(:appeal) { create(:appeal, veteran: veteran) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:distribution_task) { create(:distribution_task, parent: root_task) }
  let(:parent_hearing_task) { create(:hearing_task, parent: distribution_task) }
  let!(:schedule_hearing_task) { create(:schedule_hearing_task, parent: parent_hearing_task) }
  let!(:foreign_veteran_case_task) do
    HearingAdminActionForeignVeteranCaseTask.create!(
      appeal: appeal,
      parent: schedule_hearing_task,
      assigned_to: HearingsManagement.singleton,
      assigned_to_type: "Organization"
    )
  end
  let!(:user) { create(:user) }
  let!(:instructions_text) { "Instructions for the Schedule Hearing Task!" }

  context "UI tests" do
    before do
      HearingsManagement.singleton.add_user(user)

      User.authenticate!(user: user)
    end

    context "on queue appeal page" do
      before do
        visit("/queue/appeals/#{appeal.uuid}")
      end

      it "has foreign veteran task" do
        expect(page).to have_content(foreign_veteran_case_task.label)
      end

      it "has 'Send to Schedule Veterans list' action" do
        click_dropdown(text: Constants.TASK_ACTIONS.SEND_TO_SCHEDULE_VETERAN_LIST.label)
      end

      context "in 'Send to Schedule Veterans list' modal" do
        before do
          click_dropdown(text: Constants.TASK_ACTIONS.SEND_TO_SCHEDULE_VETERAN_LIST.label)
        end

        it "has Regional Office dropdown and notes field" do
          expect(page).to have_field("regional-office")
          expect(page).to have_field("notes")
        end

        it "can't submit form without specifying a Regional Office" do
          click_button("Confirm")

          expect(page).to have_content COPY::REGIONAL_OFFICE_REQUIRED_MESSAGE
        end

        it "can submit form with Regional Office and no notes" do
          click_dropdown({ text: "St. Petersburg, FL" }, find(".cf-modal-body"))

          click_button("Confirm")

          expect(page).to have_content COPY::SEND_TO_SCHEDULE_VETERAN_LIST_MESSAGE_TITLE
        end

        it "can submit form with Regional Office and notes" do
          click_dropdown({ text: "St. Petersburg, FL" }, find(".cf-modal-body"))
          fill_in("Notes", with: instructions_text)

          click_button("Confirm")

          expect(page).to have_content COPY::SEND_TO_SCHEDULE_VETERAN_LIST_MESSAGE_TITLE
        end
      end

      context "submitted 'Send to Schedule Veterans list' with notes" do
        let!(:user) { create(:user, roles: ["Build HearSched"]) }
        let(:cache_appeals) { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }

        before do
          click_dropdown(text: Constants.TASK_ACTIONS.SEND_TO_SCHEDULE_VETERAN_LIST.label)

          click_dropdown({ text: "St. Petersburg, FL" }, find(".cf-modal-body"))
          fill_in("Notes", with: instructions_text)

          click_button("Confirm")
        end

        it "has notes in schedule hearing task instructions" do
          expect(page).to have_content COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL

          click_button(COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL, id: schedule_hearing_task.id)

          expect(page).to have_content instructions_text
        end

        it "case shows up in schedule veterans list" do
          allow_any_instance_of(HearingDayRange).to receive(:load_days).and_return([create(:hearing_day)])

          visit("/hearings/schedule/assign?regional_office_key=RO17")
          cache_appeals

          click_button("AMA Veterans Waiting", exact: true)

          expect(page).to have_content appeal.veteran_file_number
        end
      end
    end
  end
end
