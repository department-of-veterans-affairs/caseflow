# frozen_string_literal: true

RSpec.feature "Team management page", :postgres do
  let(:user) { create(:user) }

  before do
    Bva.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  describe "Navigation to team management page" do
    context "when user is not in Bva organization" do
      let(:non_bva_user) { create(:user) }
      before { User.authenticate!(user: non_bva_user) }

      scenario "link does not appear in dropdown menu" do
        visit("/queue")
        find("#menu-trigger").click
        expect(page).to_not have_content(COPY::TEAM_MANAGEMENT_PAGE_DROPDOWN_LINK)
      end

      scenario "user is denied access to team management page" do
        visit("/team_management")
        expect(page).to have_content(COPY::UNAUTHORIZED_PAGE_ACCESS_MESSAGE)
        expect(page.current_path).to eq("/unauthorized")
      end
    end

    context "when user is in Bva organization" do
      scenario "link appears in dropdown menu" do
        visit("/queue")

        find("#menu-trigger").click
        expect(page).to have_content(COPY::TEAM_MANAGEMENT_PAGE_DROPDOWN_LINK)
      end

      scenario "user can view the team management page" do
        visit("/team_management")
        expect(page).to have_content("Judge Teams")
        expect(page).to have_content("DVC Teams")
        expect(page).to have_content("VSOs")
        expect(page).to have_content("Private Bar")
        expect(page).to have_content("VHA Program Offices")
        expect(page).to have_content("VISNs")
        expect(page).to have_content("Other teams")
      end

      context "when JudgeTeam for the judge already exists" do
        before do
          # Always return the same set of users in order to cause DuplicateJudgeTeam error
          allow_any_instance_of(UserFinder).to receive(:users).and_return([user])
        end
        scenario "user can view the team management page" do
          visit("/team_management")

          find("button", text: "+ Add Judge Team").click
          click_dropdown(text: user.full_name)
          find("button", text: "Submit").click
          expect(page).to have_content("Success")

          find("button", text: "+ Add Judge Team").click
          click_dropdown(text: user.full_name)
          find("button", text: "Submit").click
          error_message = "User #{user.id} already has a JudgeTeam. Cannot create another JudgeTeam for user."
          expect(page).to have_content(error_message)
        end
      end
    end

    context "when user is a dvc" do
      before do
        dvc = create(:user)
        DvcTeam.create_for_dvc(dvc)
        User.authenticate!(user: dvc)
      end

      scenario "link appears in dropdown menu" do
        visit("/queue")

        find("#menu-trigger").click
        expect(page).to have_content(COPY::TEAM_MANAGEMENT_PAGE_DROPDOWN_LINK)
      end

      scenario "user can view the team management page, but only judges" do
        visit("/team_management")
        expect(page).to have_content("Judge Teams")
        expect(page).to have_no_content("DVC Teams")
        expect(page).to have_no_content("VSOs")
        expect(page).to have_no_content("Private Bar")
        expect(page).to have_no_content("VHA Program Offices")
        expect(page).to have_no_content("VISNs")
        expect(page).to have_no_content("Other teams")
      end
    end
  end

  describe "Toggling priority push for a judge team" do
    let!(:judge_team) { JudgeTeam.create_for_judge(create(:user)) }

    context "when user is in Bva organization" do
      scenario "user can view priority push availablity, but cannot change it" do
        visit("/team_management")
        expect(page).to have_content("Judge Teams")
        expect(page.find("#priority-push-#{judge_team.id}_true", visible: false).checked?).to eq true
        expect(page.find("#priority-push-#{judge_team.id}_false", visible: false).checked?).to eq false
        expect(page.find("#priority-push-#{judge_team.id}_false", visible: false).disabled?).to eq true
        find(".cf-form-radio-option", text: "Unavailable").click
        expect(judge_team.reload.accepts_priority_pushed_cases).to be true
        expect(page.find("#priority-push-#{judge_team.id}_true", visible: false).checked?).to eq true
        expect(page.find("#priority-push-#{judge_team.id}_false", visible: false).checked?).to eq false
        visit("/team_management")
        expect(page.find("#priority-push-#{judge_team.id}_true", visible: false).checked?).to eq true
        expect(page.find("#priority-push-#{judge_team.id}_false", visible: false).checked?).to eq false
        expect(page.find("#priority-push-#{judge_team.id}_false", visible: false).disabled?).to eq true
      end
    end

    context "when the user is a dvc" do
      before do
        dvc = create(:user)
        DvcTeam.create_for_dvc(dvc)
        User.authenticate!(user: dvc)
      end

      scenario "user can toggele priority push availablity" do
        visit("/team_management")
        expect(page).to have_content("Judge Teams")
        expect(page.find("#priority-push-#{judge_team.id}_true", visible: false).checked?).to eq true
        expect(page.find("#priority-push-#{judge_team.id}_false", visible: false).checked?).to eq false
        find(".cf-form-radio-option", text: "Unavailable").click
        expect(page).to have_checked_field("priority-push-#{judge_team.id}_false", visible: false)
        expect(judge_team.reload.accepts_priority_pushed_cases).to be false
        visit("/team_management")
        expect(page.find("#priority-push-#{judge_team.id}_true", visible: false).checked?).to eq false
        expect(page.find("#priority-push-#{judge_team.id}_false", visible: false).checked?).to eq true
      end
    end
  end
end
