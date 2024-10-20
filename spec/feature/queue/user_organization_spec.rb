# frozen_string_literal: true

RSpec.feature "User organization", :postgres do
  let(:role) { "org_role" }
  let!(:user) { User.authenticate!(user: create(:user, roles: [role])) }
  let!(:organization) { create(:organization, name: "Test organization", url: "test", role: role) }

  let!(:user_with_role) { create(:user, full_name: "with role", roles: [role]) }
  let!(:user_without_role) { create(:user, full_name: "without role") }

  context "When user is in the organization but not an admin" do
    before { organization.add_user(user) }

    scenario "Adds and removes users from the organization" do
      visit organization.user_admin_path

      expect(page).to have_content(COPY::UNAUTHORIZED_PAGE_ACCESS_MESSAGE)
    end

    scenario "Organization task list view shows queue switcher dropdown" do
      visit organization.path
      expect(page).to have_content(COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL)
    end

    scenario "Does not have a link to the team admin page" do
      visit "/"

      find(".cf-dropdown-trigger").click
      expect(page.has_no_content?("#{organization.name} team management")).to eq(true)
    end
  end

  context "When user is admin of the organization" do
    before { OrganizationsUser.make_user_admin(user, organization) }

    scenario "Has a link to the team admin page" do
      visit "/"

      find(".cf-dropdown-trigger").click
      expect(page).to have_content("#{organization.name} team management")

      find("a", text: "#{organization.name} team management").click
      expect(page.current_path).to eq(organization.user_admin_path)
      expect(page).to have_content(format(COPY::USER_MANAGEMENT_PAGE_TITLE, organization.name))
    end

    scenario "Adds and removes users from the organization" do
      visit organization.user_admin_path

      expect(page).to have_content(format(COPY::USER_MANAGEMENT_PAGE_TITLE, organization.name))

      find(".cf-select__control", text: COPY::USER_MANAGEMENT_ADD_USER_TO_ORG_DROPDOWN_TEXT).click
      fill_in("Add user", with: user_with_role.css_id)
      expect(page).to have_content(user_with_role.full_name)
      expect(page).to_not have_content(user_without_role.full_name)

      find("div", class: "cf-select__option", text: user_with_role.full_name).click
      expect(page).to have_content(user_with_role.full_name)
      expect(user_with_role.organizations.first).to eq(organization)

      click_on "Remove-user-#{user_with_role.id}"
      expect(page).to_not have_content(user_with_role.full_name)

      expect(user_with_role.organizations.count).to eq(0)
    end

    context "when there are many users in the organization" do
      let(:other_org_user) { create(:user, full_name: "Inego Montoya") }
      before do
        organization.add_user(other_org_user)
      end

      it "allows us to change admin rights for users in the organization" do
        visit(organization.user_admin_path)

        page.assert_selector("button", text: COPY::USER_MANAGEMENT_GIVE_USER_ADMIN_RIGHTS_BUTTON_TEXT, count: 1)
        expect(organization.user_is_admin?(other_org_user)).to eq(false)

        click_on("Add-team-admin-#{other_org_user.id}")

        # Now that both members of the organization are admins we should see this text twice.
        page.assert_selector("button", text: COPY::USER_MANAGEMENT_REMOVE_USER_ADMIN_RIGHTS_BUTTON_TEXT, count: 2)
        expect(organization.user_is_admin?(other_org_user)).to eq(true)

        click_on("Remove-admin-rights-#{other_org_user.id}")
        page.assert_selector("button", text: COPY::USER_MANAGEMENT_GIVE_USER_ADMIN_RIGHTS_BUTTON_TEXT, count: 1)
        expect(organization.user_is_admin?(other_org_user)).to eq(false)
      end

      it "allows the admin to search for users in the organization by their names" do
        visit(organization.user_admin_path)
        fill_in("searchBar", with: other_org_user.full_name)
        expect(page).to have_content(other_org_user.full_name)
        expect(page).to_not have_content(user_with_role.full_name)
      end

      it "allows the admin to search for users in the organization by their css id" do
        visit(organization.user_admin_path)
        fill_in("searchBar", with: other_org_user.css_id)
        expect(page).to have_content(other_org_user.css_id)
        expect(page).to_not have_content(user_with_role.css_id)
      end

      it "displays a message if no users are found" do
        visit(organization.user_admin_path)
        fill_in("searchBar", with: "you killed my father, prepare to die")
        expect(page).to have_content("No results found")
        expect(page).to have_content("Please enter a valid username or CSS ID and try again.")
      end
    end

    context "the user is in a judge team" do
      let!(:judge) { create(:user) }
      let!(:judgeteam) { JudgeTeam.create_for_judge(judge) }

      before do
        judgeteam.add_user(user)
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

        expect(page).to have_content(format(COPY::USER_MANAGEMENT_PAGE_TITLE, organization.name))
      end
    end
  end

  context "When organization is a BusinessLine" do
    let!(:organization) { create(:business_line, url: "lob", name: "LOB") }

    before { organization.add_user(user) }

    scenario "Redirects to /decision_reviews equivalent" do
      visit organization.path

      expect(current_path).to eq "/decision_reviews/lob"
      expect(page).to have_content("Reviews needing action")
    end
  end
end
