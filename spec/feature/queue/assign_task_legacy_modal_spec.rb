# frozen_string_literal: true

RSpec.feature "AssigTaskModal", :all_dbs do
  let!(:scm_user) { create(:user) }
  let!(:user) { create(:user) }

  let!(:judge_user) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
  let!(:judgeteam) { JudgeTeam.create_for_judge(judge_user) }
  let!(:veteran) { create(:veteran, first_name: "Samuel", last_name: "Purcell") }
  let!(:ssn) { Generators::Random.unique_ssn }
  let(:judge_one) { create(:user, full_name: "Apurva Judge_CaseAtDispatch Wakefield") }
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
    end
  end
end
