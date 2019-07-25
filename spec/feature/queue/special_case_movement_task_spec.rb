# frozen_string_literal: true

require "rails_helper"

RSpec.feature "SpecialCaseMovementTask" do
  let(:scm_user) { FactoryBot.create(:user) }
  let!(:judge) do
    create(:user, css_id: "BVAAABSHIRE", full_name: "Judge Abshire")
    create(:staff, :judge_role, sdomainid: "BVAAABSHIRE", snamel: "Abshire", snamef: "Judge")
  end
  let!(:appeal) do
    FactoryBot.create(:appeal,
                      :with_post_intake_tasks,
                      docket_type: Constants.AMA_DOCKETS.direct_review)
  end

  before do
    OrganizationsUser.add_user_to_organization(scm_user,
                                               SpecialCaseMovementTeam.singleton)
    User.authenticate!(user: scm_user)
  end
  describe "Special Case Movement Team Memeber" do
    context "With the Appeal in the right state" do
      it "successfully assigns the task to judge" do
        visit("queue/appeals/#{appeal.external_id}")


        prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
        text = Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.label
        click_dropdown(prompt: prompt, text: text)

        # Select a judge, fill in instructions, submit
        click_dropdown(prompt: COPY::SPECIAL_CASE_MOVEMENT_MODAL_SELECTOR_PLACEHOLDER,
                       text: judge.full_name)
        fill_in("taskInstructions", with: "instructions")
        click_button("Submit")

        # Auth as judge user
        # Expect to find case in Assign Queue
        # Expect to see the SCM in the timeline
      end
    end
  end
end
