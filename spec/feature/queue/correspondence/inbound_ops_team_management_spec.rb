# frozen_string_literal: true

RSpec.feature "InboundOpsTeamManagement" do
  let(:inbound_ops_team) { InboundOpsTeam.singleton }
  let(:inbound_ops_user) { create(:user, full_name: "INBOUND OPS USER", css_id: "INBOUND_OPS_USER") }
  let(:inbound_ops_admin) { create(:user, full_name: "INBOUND OPS ADMIN", css_id: "INBOUND_OPS_ADMIN") }

  before do
    inbound_ops_team.add_user(inbound_ops_user)
    inbound_ops_team.add_user(inbound_ops_admin)
    OrganizationsUser.make_user_admin(inbound_ops_admin, inbound_ops_team)
    User.authenticate!(user: inbound_ops_user)
    User.authenticate!(user: inbound_ops_admin)
    FeatureToggle.enable!(:correspondence_queue)
  end

  describe "Navigation to Inbound Ops Team Management page" do
    context "when user is not in Bva organization" do
      let(:non_inbound_ops_user) { create(:user) }
      before { User.authenticate!(user: non_inbound_ops_user) }

      scenario "link does not appear in dropdown menu" do
        visit("/queue")
        find("#menu-trigger").click
        expect(page).to_not have_content(COPY::INBOUND_OPS_TEAM_DROPDOWN_LINK)
      end

      scenario "user is denied access to team management page" do
        visit("/team_management")
        expect(page).to have_content(COPY::UNAUTHORIZED_PAGE_ACCESS_MESSAGE)
        expect(page.current_path).to eq("/unauthorized")
      end
    end

    context "when user is in the InboundOpsTeam organization" do
      scenario "link appears in dropdown menu" do
        visit_inbound_ops_team_management
      end

      scenario "user can view the team management page" do
        visit_inbound_ops_team_management

        inbound_ops_team.users.each do |user|
          expect(page).to have_content(user.css_id)
          expect(page).to have_content(user.full_name)
        end
      end
    end
  end

  private

  def visit_inbound_ops_team_management
    visit("/queue")

    find("#menu-trigger").click
    expect(page).to have_content("Inbound Ops Team team management")
    click_on("Inbound Ops Team team management")

    expect(current_path).to eq("/organizations/inbound-ops-team/users")
  end
end
