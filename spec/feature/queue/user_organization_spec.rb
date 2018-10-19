require "rails_helper"

RSpec.feature "User organization" do
  let(:role) { "org_role" }
  let!(:staff) { create(:staff, :attorney_role, sdomainid: user.css_id, sdept: "TRANS") }
  let!(:user) { User.authenticate!(user: create(:user, roles: [role])) }
  let!(:organization) { create(:organization, name: "Test organization", url: "test", feature: nil, role: role) }
  let!(:organization_user) { OrganizationsUser.add_user_to_organization(user, organization) }
  let!(:staff_field) { StaffFieldForOrganization.create!(organization: organization, name: "sdept", values: %w[TRANS]) }

  let!(:user_with_role) { create(:user, full_name: "with role", roles: [role]) }
  let!(:user_without_role) { create(:user, full_name: "without role") }

  scenario "submits draft decision" do
    visit "/organizations/#{organization.url}/users"

    expect(page).to have_content("#{organization.name} team")

    find(".Select-control", text: "Select user to add").click
    expect(page).to have_content(user_with_role.full_name)
    expect(page).to_not have_content(user_without_role.full_name)

    find("div", class: "Select-option", text: user_with_role.full_name).click

    expect(page).to have_content(user_with_role.full_name)
    expect(user_with_role.organizations.first).to eq(organization)

    click_on "Remove-user-2"

    visit "/organizations/#{organization.url}/users"
    expect(page).to_not have_content(user_with_role.full_name)
    expect(user_with_role.organizations.count).to eq(0)
  end
end
