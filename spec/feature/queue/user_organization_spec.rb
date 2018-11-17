require "rails_helper"

RSpec.feature "User organization" do
  let(:role) { "org_role" }
  let!(:user) { User.authenticate!(user: create(:user, roles: [role])) }
  let!(:organization) { create(:organization, name: "Test organization", url: "test", role: role) }

  let!(:user_with_role) { create(:user, full_name: "with role", roles: [role]) }
  let!(:user_without_role) { create(:user, full_name: "without role") }

  context "When user is in the organization" do
    let!(:organization_user) { OrganizationsUser.add_user_to_organization(user, organization) }

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
  end

  context "When user is not in the organization" do
    scenario "Adds and removes users from the organization" do
      visit organization.user_admin_path

      expect(page).to have_content("You aren't authorized")
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
