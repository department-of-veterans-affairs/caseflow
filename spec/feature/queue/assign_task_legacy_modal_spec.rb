# frozen_string_literal: true

RSpec.feature "AssigTaskModal", :all_dbs do
  let!(:scm_user) { create(:user) }
  let!(:user) { create(:user) }

  let!(:judge_user) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
  let!(:judgeteam) { JudgeTeam.create_for_judge(judge_user) }
  let!(:veteran) { create(:veteran, first_name: "Samuel", last_name: "Purcell") }
  let!(:ssn) { Generators::Random.unique_ssn }

  let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "#{ssn}S")) }
  let!(:root_task) { create(:root_task, appeal: appeal, assigned_to: user) }
  let!(:assign_task) { create(:ama_judge_assign_task, assigned_to: user, parent: root_task) }

  before do
    SpecialCaseMovementTeam.singleton.add_user(scm_user)
    User.authenticate!(user: scm_user)
  end
  describe "Testing assign task model for Legacy appeal" do
    context "With the Appeal in the right state" do
      it "Testing VLJ to VLJ with SpecialCaseMovementTeam user" do
        visit("queue/appeals/#{assign_task.appeal.external_id}")
        dropdown = find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL)
        dropdown.click
        expect(page).to have_content(Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.label)
      end

      it "Checking validations on Assign Task modal windows VLJ to VLJ SpecialCaseMovementTeam user" do
        visit("/queue")
        visit("/queue/appeals/#{assign_task.appeal.external_id}")
        prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
        text = Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.label
        click_dropdown(prompt: prompt, text: text)

        # check modal content
        expect(page).to have_content(format(COPY::ASSIGN_TASK_TITLE))
        expect(page).to have_button("Assign", disabled: true)

        page.all(".cf-form-radio-option > label")[1].click

        expect(page).to have_button(COPY::JUDGE_ASSIGN_TASK_LABEL, disabled: true)

        # fill out instructions
        fill_in("cancellationInstructions", with: "instructions")
        expect(page).to have_button(COPY::JUDGE_ASSIGN_TASK_LABEL, disabled: false)

        # remove instructions in text field
        fill_in("cancellationInstructions", with: "")
        expect(page).to have_button(COPY::JUDGE_ASSIGN_TASK_LABEL, disabled: true)

        click_button "Cancel"
        expect(page).to have_content "Currently active tasks"
      end
    end
  end
end
