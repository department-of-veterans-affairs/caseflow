# frozen_string_literal: true

RSpec.feature "SpecialCaseMovementTask", :all_dbs do
  let(:scm_user) { create(:user) }

  let(:judge_user) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
  let!(:judgeteam) { JudgeTeam.create_for_judge(judge_user) }
  let(:veteran) { create(:veteran, first_name: "Samuel", last_name: "Purcell") }
  let(:appeal) do
    create(:appeal,
           :with_post_intake_tasks,
           veteran: veteran,
           docket_type: Constants.AMA_DOCKETS.direct_review)
  end

  before do
    SpecialCaseMovementTeam.singleton.add_user(scm_user)
    User.authenticate!(user: scm_user)
  end
  describe "Special Case Movement Team Member" do
    context "With the Appeal in the right state" do
      it "successfully assigns the task to judge" do
        visit("queue/appeals/#{appeal.external_id}")

        prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
        text = Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.label
        click_dropdown(prompt: prompt, text: text)

        # Select a judge, fill in instructions, submit
        click_dropdown(prompt: COPY::SPECIAL_CASE_MOVEMENT_MODAL_SELECTOR_PLACEHOLDER,
                       text: judge_user.full_name)
        fill_in("taskInstructions", with: "instructions")
        click_button("Submit")

        expect(page).to have_content(COPY::ASSIGN_TASK_SUCCESS_MESSAGE % judge_user.full_name)
        # Auth as judge user
        User.authenticate!(user: judge_user)
        visit "/queue"
        find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
        expect(page).to have_content(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user.css_id))
        click_on format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user.css_id)
        expect(page).to have_content("Cases to Assign")
        # Expect to find case in Assign Queue
        expect(page).to have_content("#{veteran.first_name} #{veteran.last_name}")
        # Expect to see the SCM in the timeline
        click_on "#{veteran.first_name} #{veteran.last_name}"
        expect(page).to have_content(SpecialCaseMovementTask.name)
      end
    end
  end
end
