require "rails_helper"

RSpec.feature "User organization" do
  let(:role) { "org_role" }
  let!(:user) { User.authenticate!(user: create(:user, roles: [role])) }
  let!(:organization) { create(:organization, name: "Test organization", url: "test", role: role) }

  let!(:user_with_role) { create(:user, full_name: "with role", roles: [role]) }
  let!(:user_without_role) { create(:user, full_name: "without role") }

  context "When user is in the organization but not an admin" do
    before { OrganizationsUser.add_user_to_organization(user, organization) }

    scenario "Adds and removes users from the organization" do
      visit organization.user_admin_path

      expect(page).to have_content(COPY::UNAUTHORIZED_PAGE_ACCESS_MESSAGE)
    end

    scenario "Organization task list view shows queue switcher dropdown" do
      visit organization.path
      expect(page).to have_content(COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL)
    end
  end

  context "When user is admin of the organization" do
    before { OrganizationsUser.make_user_admin(user, organization) }

    scenario "Adds and removes users from the organization" do
      visit organization.user_admin_path

      expect(page).to have_content("#{organization.name} team")

      find(".Select-control", text: "Select user to add").click
      expect(page).to have_content(user_with_role.full_name)
      expect(page).to_not have_content(user_without_role.full_name)

      find("div", class: "Select-option", text: user_with_role.full_name).click

      expect(page).to have_content(user_with_role.full_name)
      expect(user_with_role.organizations.first).to eq(organization)

      click_on "Remove-user-#{user_with_role.id}"
      expect(page).to_not have_content(user_with_role.full_name)

      expect(user_with_role.organizations.count).to eq(0)
    end

    context "the user is in a judge team" do
      let!(:judge) { FactoryBot.create(:user) }
      let!(:judgeteam) { JudgeTeam.create_for_judge(judge) }

      before do
        OrganizationsUser.add_user_to_organization(user, judgeteam)
      end

      it "Organization task list view shows queue switcher dropdown" do
        visit organization.path
        expect(page).to have_content(COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL)

        find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
        expect(page).to have_content(organization.name)
        expect(page).to_not have_content(judgeteam.name)
      end
    end
  end

  context "When user is not in the organization" do
    scenario "Adds and removes users from the organization" do
      visit organization.user_admin_path

      expect(page).to have_content(COPY::UNAUTHORIZED_PAGE_ACCESS_MESSAGE)
    end

    context "but user is a system admin" do
      before do
        Functions.grant!("System Admin", users: [user.css_id])
      end

      scenario "Adds and removes users from the organization" do
        visit organization.user_admin_path

        expect(page).to have_content("#{organization.name} team")
      end
    end
  end
end
