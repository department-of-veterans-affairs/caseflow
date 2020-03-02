# frozen_string_literal: true

RSpec.feature "SCM Team access to judge assignment features", :all_dbs do
  let(:judge_one) { Judge.new(create(:user, full_name: "Billie Daniel")) }
  let(:judge_two) { Judge.new(create(:user, full_name: "Joe Shmoe")) }
  let!(:vacols_user_one) { create(:staff, :judge_role, user: judge_one.user) }
  let!(:vacols_user_two) { create(:staff, :judge_role, user: judge_two.user) }
  let!(:judge_one_team) { JudgeTeam.create_for_judge(judge_one.user) }
  let!(:judge_two_team) { JudgeTeam.create_for_judge(judge_two.user) }
  let(:attorney_one) { create(:user, full_name: "Moe Syzlak") }
  let(:attorney_two) { create(:user, full_name: "Alice Macgyvertwo") }
  let(:team_attorneys) { [attorney_one, attorney_two] }
  let(:appeal_one) { create(:appeal) }
  let(:appeal_two) { create(:appeal) }

  let!(:scm_user) { create(:user, full_name: "Rosalie SCM Dunkle") }
  let(:current_user) { scm_user }

  before do
    team_attorneys.each do |attorney|
      create(:staff, :attorney_role, user: attorney)
      judge_one_team.add_user(attorney)
    end

    SpecialCaseMovementTeam.singleton.add_user(scm_user)
    User.authenticate!(user: current_user)

    FeatureToggle.enable!(:scm_view_judge_assign_queue)
  end

  after { FeatureToggle.disable!(:scm_view_judge_assign_queue) }

  context "SCM user can see judge assign queue page" do
    let!(:vacols_user_one_acting_judge) { create(:staff, :attorney_judge_role, user: judge_one.user) }

    scenario "visits 'Assign' view" do
      visit "/queue/#{judge_one.user.id}/assign?scm=true&judge_css_id=#{judge_one.user.css_id}"

      expect(page).to have_content("Cases to Assign")
      expect(page).to have_content("Moe Syzlak")
      expect(page).to have_content("Alice Macgyvertwo")

      expect(page.find(".usa-sidenav-list")).to have_content attorney_one.full_name
      expect(page.find(".usa-sidenav-list")).to have_content attorney_two.full_name

      safe_click ".Select"
      expect(page.find(".dropdown-Assignee")).to have_content attorney_one.full_name
      expect(page.find(".dropdown-Assignee")).to have_content attorney_two.full_name

      click_dropdown(text: "Other")
      safe_click ".dropdown-Other"
      # expect attorneys and acting judges but not judges
      expect(page.find(".dropdown-Other")).to have_content judge_one.user.full_name
      expect(page.find(".dropdown-Other")).to have_no_content judge_two.user.full_name
      expect(page.find(".dropdown-Other")).to have_content attorney_one.full_name
      expect(page.find(".dropdown-Other")).to have_content attorney_two.full_name

      expect(page).to have_content "Request more cases"
    end
  end

  context "Non-SCM user cannot see judge assign queue page" do
    context "logged in user is some user" do
      let(:current_user) { create(:user, full_name: "Odd ManOutthree") }

      scenario "visits 'Assign' view" do
        visit "/queue/#{judge_one.user.id}/assign?scm=true&judge_css_id=#{judge_one.user.css_id}"

        expect(page).to have_content("Additional access needed")
      end
    end
    context "logged in user is attorney on the team" do
      let(:current_user) { attorney_one }

      scenario "visits 'Assign' view" do
        visit "/queue/#{judge_one.user.id}/assign?scm=true&judge_css_id=#{judge_one.user.css_id}"

        expect(page).to have_content("Additional access needed")
      end
    end
    context "logged in user is attorney on the team with judge role" do
      let!(:vacols_atty_one_acting_judge) { create(:staff, :attorney_judge_role, user: attorney_one) }
      let(:current_user) { attorney_one }

      scenario "visits 'Assign' view" do
        visit "/queue/#{judge_one.user.id}/assign?scm=true&judge_css_id=#{judge_one.user.css_id}"

        expect(page).to have_content("Additional access needed")
      end
    end
  end

  context "Can view their queue" do
    let(:appeal) { create(:appeal) }
    let(:veteran) { appeal.veteran }
    let!(:root_task) { create(:root_task, appeal: appeal) }

    before do
      create(:ama_judge_task, :in_progress, assigned_to: judge_one.user, appeal: appeal_one)
      create(:ama_judge_task, :in_progress, assigned_to: judge_one.user, appeal: appeal_two)
    end

    context "there's another in-progress JudgeAssignTask" do
      let!(:judge_task) do
        create(:ama_judge_task, :in_progress, assigned_to: judge_one.user, appeal: appeal, parent: root_task)
      end

      scenario "viewing the assign task queue" do
        visit "/queue/#{judge_one.user.id}/assign?scm=true&judge_css_id=#{judge_one.user.css_id}"

        expect(page).to have_content("Assign 3 Cases")
        expect(page).to have_content("#{veteran.first_name} #{veteran.last_name}")
        expect(page).to have_content(appeal.veteran_file_number)
        expect(page).to have_content("Original")
        expect(page).to have_content(appeal.docket_number)
      end
    end
  end
end
