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
        expect(page).to have_content("Education Regional Processing Offices")
        expect(page).to have_content("Other teams")
      end

      shared_examples "user cannot add another team" do |team_type|
        before do
          # Always return the same set of users in order to cause DuplicateJudgeTeam error
          allow_any_instance_of(UserFinder).to receive(:users).and_return([user])
        end
        scenario "user cannot add another team" do
          visit("/team_management")

          find("button", text: "+ Add #{team_type}").click
          click_dropdown(text: user.full_name)
          find("button", text: "Submit").click
          expect(page).to have_content("Success")

          find("button", text: "+ Add #{team_type}").click
          click_dropdown({ text: user.full_name }, find(".cf-modal")) # specify container due to multiple dropdowns
          find("button", text: "Submit").click
          expect(page).to have_content(error_message)

          find("button", text: "Cancel").click
          expect(page).not_to have_content(error_message)
        end
      end

      context "when DvcTeam for the user already exists" do
        let(:error_message) { "User #{user.id} already has a DvcTeam. Cannot create another DvcTeam for user." }
        include_examples "user cannot add another team", "DVC Team"
      end

      context "when JudgeTeam for the judge already exists" do
        let(:error_message) { "User #{user.id} already has a JudgeTeam. Cannot create another JudgeTeam for user." }
        include_examples "user cannot add another team", "Judge Team"
      end

      scenario "user cannot create VSO or PrivateBar with the same participant_id" do
        participant_id = "1234567"
        error_message = "Participant ID #{participant_id} is already used for existing team 'Vso 1'. Cannot create"

        step "add a VSO" do
          visit("/team_management")
          find("button", text: "+ Add VSO").click
          fill_in "Name", with: "Vso 1"
          fill_in "URL", with: "vso-1"
          fill_in "BGS Participant ID", with: participant_id
          find("button", text: "Submit").click
        end

        step "try to add another VSO with the same participant id" do
          find("button", text: "+ Add VSO").click
          fill_in "Name", with: "Vso 2"
          fill_in "URL", with: "vso-2"
          fill_in "BGS Participant ID", with: participant_id
          find("button", text: "Submit").click
          expect(page).to have_content(error_message)

          find("button", text: "Cancel").click
          expect(page).not_to have_content(error_message)
        end

        step "try to add a Private Bar with the same participant id" do
          find("button", text: "+ Add Private Bar").click
          fill_in "Name", with: "Private Bar 1"
          fill_in "URL", with: "pb-1"
          fill_in "BGS Participant ID", with: participant_id
          find("button", text: "Submit").click
          expect(page).to have_content(error_message)

          find("button", text: "Cancel").click
          expect(page).not_to have_content(error_message)
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
        expect(page).to have_no_content("Education Regional Processing Offices")
        expect(page).to have_no_content("Other teams")
      end
    end
  end

  describe "Toggling distribution toggles for a judge team" do
    let!(:judge_team) { JudgeTeam.create_for_judge(create(:user)) }

    context "when user is in Bva organization" do
      scenario "user can view priority push availablity, but cannot change it" do
        visit("/team_management")
        expect(page).to have_content("Judge Teams")
        expect(page).to have_field("priority-case-distribution-#{judge_team.id}", visible: false, disabled: true)

        expect(judge_team.reload.accepts_priority_pushed_cases).to be true
      end

      scenario "user can view requested distribution availablity, but cannot change it" do
        visit("/team_management")
        expect(page).to have_content("Judge Teams")
        expect(page).to have_field("requested-distribution-#{judge_team.id}", visible: false, disabled: true)

        expect(judge_team.reload.accepts_priority_pushed_cases).to be true
      end
    end

    context "when the user is a dvc" do
      before do
        dvc = create(:user)
        DvcTeam.create_for_dvc(dvc)
        User.authenticate!(user: dvc)
      end

      scenario "user can toggle priority push availablity" do
        visit("/team_management")
        expect(page).to have_content("Judge Teams")

        # Should be true by default
        expect(judge_team.reload.accepts_priority_pushed_cases).to be true

        # Setting "Unavailable" should result in priority push being disabled
        expect(page).to have_field("priority-case-distribution-#{judge_team.id}", visible: false, disabled: false)
        find(".dropdown-priorityCaseDistribution-#{judge_team.id} .cf-select__control").click
        find("div", class: "cf-select__option", text: "Unavailable").click

        # Wait for save, then check that value has updated to false
        expect(page).to have_content "Saved"
        expect(judge_team.reload.accepts_priority_pushed_cases).to be false

        # Setting "AMA cases only" should result in priority push being enabled
        expect(page).to have_field("priority-case-distribution-#{judge_team.id}", visible: false, disabled: false)
        find(".dropdown-priorityCaseDistribution-#{judge_team.id} .cf-select__control").click
        find("div", class: "cf-select__option", text: "AMA cases only").click

        # Wait for save, then check that both relevant values have updated to true
        expect(page).to have_content "Saved"
        expect(judge_team.reload.accepts_priority_pushed_cases).to be true
        expect(judge_team.reload.ama_only_push).to be true
      end

      scenario "user can toggle AMA-only setting for requested distribution" do
        visit("/team_management")
        expect(page).to have_content("Judge Teams")

        # Should be false by default
        expect(judge_team.reload.ama_only_request).to be false

        # Setting "AMA cases only" should result in priority push being enabled
        expect(page).to have_field("requested-distribution-#{judge_team.id}", visible: false, disabled: false)
        find(".dropdown-requestedDistribution-#{judge_team.id} .cf-select__control").click
        find("div", class: "cf-select__option", text: "AMA cases only").click

        # Wait for save, then check that value has updated to true
        expect(page).to have_content "Saved"
        expect(judge_team.reload.ama_only_request).to be true
      end
    end
  end
end
