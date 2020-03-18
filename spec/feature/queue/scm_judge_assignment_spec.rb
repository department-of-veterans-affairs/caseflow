# frozen_string_literal: true

RSpec.feature "SCM Team access to judge assignment features", :all_dbs do
  let(:judge_one) { Judge.new(create(:user, full_name: "Billie Daniel")) }
  let(:judge_two) { Judge.new(create(:user, full_name: "Joe Shmoe")) }
  let(:acting_judge) { Judge.new(create(:user, full_name: "Acting Judge")) }
  let!(:vacols_user_one) { create(:staff, :judge_role, user: judge_one.user) }
  let!(:vacols_user_two) { create(:staff, :judge_role, user: judge_two.user) }
  let!(:vacols_user_acting) { create(:staff, :attorney_judge_role, user: acting_judge.user) }
  let!(:judge_one_team) { JudgeTeam.create_for_judge(judge_one.user) }
  let!(:judge_two_team) { JudgeTeam.create_for_judge(judge_two.user) }
  let(:attorney_one) { create(:user, full_name: "Moe Syzlak") }
  let(:attorney_two) { create(:user, full_name: "Alice Macgyvertwo") }
  let(:team_attorneys) { [attorney_one, attorney_two] }

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

  context "Non-SCM user should not see judge assign queue page if they are not the judge" do
    context "logged in user is some user" do
      let(:current_user) { create(:user, full_name: "Odd ManOutthree") }

      scenario "visits 'Assign' view" do
        visit "/queue/#{judge_one.user.id}/assign"

        expect(page).to have_content("Additional access needed")
      end
    end
    context "logged in user is attorney on the team" do
      let(:current_user) { attorney_one }

      scenario "visits 'Assign' view" do
        visit "/queue/#{judge_one.user.id}/assign"

        expect(page).to have_content("Additional access needed")
      end
    end
    context "logged in user is attorney on the team with judge role" do
      let!(:vacols_atty_one_acting_judge) { create(:staff, :attorney_judge_role, user: attorney_one) }
      let(:current_user) { attorney_one }

      scenario "visits 'Assign' view" do
        visit "/queue/#{judge_one.user.id}/assign"

        expect(page).to have_content("Additional access needed")
      end
    end
  end

  context "SCM user can view judge's queue" do
    let!(:appeal) { create(:appeal, :assigned_to_judge, associated_judge: judge_one.user) }
    let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case, staff: vacols_user_one)) }

    scenario "with both ama and legacy case" do
      visit "/queue/#{judge_one.user.id}/assign"

      expect(page).to have_content("Assign 2 Cases for #{judge_one.user.css_id}")

      expect(page).to have_content("#{appeal.veteran.first_name} #{appeal.veteran.last_name}")
      expect(page).to have_content(appeal.veteran_file_number)
      expect(page).to have_content("Original")
      expect(page).to have_content(appeal.docket_number)

      expect(page).to have_content("#{legacy_appeal.veteran_first_name} #{legacy_appeal.veteran_last_name}")
      expect(page).to have_content(legacy_appeal.veteran_file_number)
      expect(page).to have_content(legacy_appeal.docket_number)

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
      expect(page.find(".dropdown-Other")).to have_content acting_judge.user.full_name
      expect(page.find(".dropdown-Other")).to have_no_content judge_one.user.full_name
      expect(page.find(".dropdown-Other")).to have_no_content judge_two.user.full_name
      expect(page.find(".dropdown-Other")).to have_content attorney_one.full_name
      expect(page.find(".dropdown-Other")).to have_content attorney_two.full_name

      expect(page).to have_content "Request more cases"
    end

    context "and can request cases for a judge" do
      let!(:appeal) { create(:appeal, :ready_for_distribution) }

      before do
        allow_any_instance_of(LegacyDocket).to receive(:weight).and_return(101.4)
        allow_any_instance_of(DirectReviewDocket).to receive(:weight).and_return(10)
        allow_any_instance_of(DirectReviewDocket).to receive(:nonpriority_receipts_per_year).and_return(100)
        allow(Docket).to receive(:nonpriority_decisions_per_year).and_return(1000)
      end

      scenario "viewing the assign task queue" do
        visit "/queue/#{judge_one.user.id}/assign"

        expect(page).to have_content("Assign 1 Cases for #{judge_one.user.css_id}")
        expect(page).to_not have_content("#{appeal.veteran.first_name} #{appeal.veteran.last_name}")

        click_on("Request more cases")
        expect(page).to have_content("Distribution complete")

        expect(page).to have_content("Assign 2 Cases for #{judge_one.user.css_id}")

        expect(page).to have_content(appeal.veteran_file_number)
        expect(page).to have_content("Original")
        expect(page).to have_content(appeal.docket_number)
      end
    end
  end
end
