# frozen_string_literal: true

RSpec.feature "Users management page", :postgres do
  let(:user) { create(:user) }

  before do
    Bva.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  describe "Navigation to user management page" do
    context "when user is not in Bva organization" do
      let(:non_bva_user) { create(:user) }
      before { User.authenticate!(user: non_bva_user) }

      scenario "link does not appear in dropdown menu" do
        visit("/queue")
        find("#menu-trigger").click
        expect(page).to_not have_content(COPY::USER_MANAGEMENT_PAGE_DROPDOWN_LINK)
      end

      scenario "user is denied access to user management page" do
        visit("/user_management")
        expect(page).to have_content(COPY::UNAUTHORIZED_PAGE_ACCESS_MESSAGE)
        expect(page.current_path).to eq("/unauthorized")
      end
    end

    context "when user is in Bva organization" do
      scenario "link appears in dropdown menu" do
        visit("/queue")

        find("#menu-trigger").click
        expect(page).to have_content(COPY::USER_MANAGEMENT_PAGE_DROPDOWN_LINK)
      end
    end
  end

  describe "When marking a user inactive" do
    let!(:active_user) { create(:user) }
    let!(:inactive_user) { create(:user, status: Constants.USER_STATUSES.inactive) }

    it "allow a BVA Admin to toggle a user's status" do
      step "navigate to user management page" do
        visit("/queue")
        find("#menu-trigger").click
        find_link(COPY::USER_MANAGEMENT_PAGE_DROPDOWN_LINK).click
        expect(page).to have_content(COPY::USER_MANAGEMENT_STATUS_PAGE_TITLE)
        expect(page).to have_content(COPY::USER_MANAGEMENT_PAGE_DESCRIPTION)
      end

      step "user searches for an existant user" do
        fill_in COPY::USER_MANAGEMENT_FIND_USER_DROPDOWN_NAME, with: active_user.css_id
        expect(page).to have_content(active_user.full_name)

        find("div", class: "cf-select__option", text: active_user.full_name).click
        expect(page).to have_content("#{active_user.full_name} (#{active_user.css_id})")
      end

      step "user marks another user inactive" do
        expect(page).to have_content(COPY::USER_MANAGEMENT_GIVE_USER_INACTIVE_STATUS_BUTTON_TEXT)
        page.find("button", text: COPY::USER_MANAGEMENT_GIVE_USER_INACTIVE_STATUS_BUTTON_TEXT).click
        expect(page).to have_content(COPY::USER_MANAGEMENT_GIVE_USER_ACTIVE_STATUS_BUTTON_TEXT)
        expect(page).to have_content(
          format(COPY::USER_MANAGEMENT_INACTIVE_SUCCESS_TITLE, "#{active_user.full_name} (#{active_user.css_id})")
        )
        expect(page).to have_content(
          format(COPY::USER_MANAGEMENT_INACTIVE_SUCCESS_BODY, "#{active_user.full_name} (#{active_user.css_id})")
        )
        expect(inactive_user.reload.status).to eq(Constants.USER_STATUSES.inactive)
      end

      step "user marks another user active" do
        visit "/user_management"
        fill_in COPY::USER_MANAGEMENT_FIND_USER_DROPDOWN_NAME, with: inactive_user.css_id
        expect(page).to have_content(inactive_user.full_name)

        find("div", class: "cf-select__option", text: inactive_user.full_name).click
        expect(page).to have_content("#{inactive_user.full_name} (#{inactive_user.css_id})")
        expect(page).to have_content(COPY::USER_MANAGEMENT_GIVE_USER_ACTIVE_STATUS_BUTTON_TEXT)
        page.find("button", text: COPY::USER_MANAGEMENT_GIVE_USER_ACTIVE_STATUS_BUTTON_TEXT).click
        expect(page).to have_content(COPY::USER_MANAGEMENT_GIVE_USER_INACTIVE_STATUS_BUTTON_TEXT)
        expect(page).to have_content(
          format(COPY::USER_MANAGEMENT_ACTIVE_SUCCESS_TITLE, "#{inactive_user.full_name} (#{inactive_user.css_id})")
        )
        expect(page).to have_content(
          format(COPY::USER_MANAGEMENT_ACTIVE_SUCCESS_BODY, "#{inactive_user.full_name} (#{inactive_user.css_id})")
        )
        expect(inactive_user.reload.status).to eq(Constants.USER_STATUSES.active)
      end
    end
  end
end
