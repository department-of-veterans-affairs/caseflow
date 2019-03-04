require "rails_helper"

RSpec.feature "Team management page" do
  let(:user) { FactoryBot.create(:user) }

  let(:judge_team_count) { 3 }
  let(:vso_count) { 4 }
  let(:other_org_count) { 9 }

  before do
    Fakes::Initializer.load!
    OrganizationsUser.add_user_to_organization(user, Bva.singleton)
    User.authenticate!(user: user)

    judge_team_count.times { JudgeTeam.create_for_judge(FactoryBot.create(:user)) }
    FactoryBot.create_list(:vso, vso_count)
    # Create one less organization than the count to account for the existing Bva organization.
    FactoryBot.create_list(:organization, other_org_count - 1)
  end

  describe "Navigation to team management page" do
    context "when user is not in Bva organization" do
      let(:non_bva_user) { FactoryBot.create(:user) }
      before { User.authenticate!(user: non_bva_user) }

      scenario "link does not appear in dropdown menu" do
        visit("/queue")
        click_on(non_bva_user.css_id)
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

        click_on(user.css_id)
        expect(page).to have_content(COPY::TEAM_MANAGEMENT_PAGE_DROPDOWN_LINK)
        click_on(COPY::TEAM_MANAGEMENT_PAGE_DROPDOWN_LINK)

        expect(page).to have_content(COPY::TEAM_MANAGEMENT_PAGE_HEADER)
        expect(page.current_path).to eq("/team_management")
      end
    end
  end

  describe "Adding a new judge team" do
    context "when some users exist in the database" do
      before { FactoryBot.create_list(:user, 6) }
      it "successfully adds the judge team" do
        visit("/team_management")

        click_on(COPY::TEAM_MANAGEMENT_ADD_JUDGE_BUTTON)
        expect(page.current_path).to eq("/team_management/add_judge_team")
        expect(page).to have_content(COPY::TEAM_MANAGEMENT_ADD_JUDGE_TEAM_MODAL_TITLE)

        click_dropdown(prompt: COPY::TEAM_MANAGEMENT_SELECT_JUDGE_LABEL, index: 2)
        click_on(COPY::MODAL_SUBMIT_BUTTON)

        expect(JudgeTeam.count).to eq(judge_team_count + 1)
      end
    end
  end
end
