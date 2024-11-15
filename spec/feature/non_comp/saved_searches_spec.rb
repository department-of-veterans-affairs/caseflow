# frozen_string_literal: true

feature "Saved Searches", :postgres do
  let(:non_comp_org) { VhaBusinessLine.singleton }
  let(:user) { create(:default_user, css_id: "REPORT USER", full_name: "Report User") }
  let(:vha_saved_searches_url) { "/decision_reviews/vha/searches" }

  before do
    User.stub = user
    non_comp_org.add_user(user)
    OrganizationsUser.make_user_admin(user, non_comp_org)
    visit vha_saved_searches_url
  end

  it "admin user" do
    step "saved searches should be accessable to VHA Admin user" do
      expect(page).to have_content("Saved Searches")
    end
    step "can navigate back to report page" do
      click_link "Back to Generate task report"
      expect(current_url).to include("/decision_reviews/vha/report")
      expect(current_url).not_to include("searches")
    end
  end

  describe "checking saved search tables" do
    let!(:user_saved_search) { create(:saved_search, user: user) }
    let!(:all_saved_searches) { create_list(:saved_search, 5) }

    before do
      visit vha_saved_searches_url
    end

    context "check save search page is rendering user's searches and all searches" do
      it "When VHA admin user clicks on All Saved Searches should see all saved searches" do
        page.find("button", text: "All saved searches").click
        table = page.find("tbody")

        expect(page).to have_text("Viewing 1-6 of 6 total")
        expect(table).to have_selector("tr", count: 6)
      end

      it "When VHA admin user clicks on my Saved Searches should see their saved searches" do
        page.find("button", text: "My saved searches").click
        table = page.find("tbody")

        expect(page).to have_text("Viewing 1-1 of 1 total")
        expect(table).to have_selector("tr", count: 1)
      end

      it "should have delete button that is disabled." do
        delete_buttom = find("button", text: "Delete")
        expect(delete_buttom[:disabled]).to eq "true"
      end

      it "should have delete button that will be enabled after radio button is selected." do
        select_row_radio = page.find(".cf-form-radio-option")
        select_row_radio.click

        delete_buttom = find("button", text: "Delete")

        expect(delete_buttom[:disabled]).to eq "false"
      end

      it "should open delete modal and deleting button should remove the saved search" do
        select_row_radio = page.find(".cf-form-radio-option")
        select_row_radio.click

        find("button", text: "Delete").click

        within ".cf-modal-body" do
          expect(page).to have_content("Delete Search")
          expect(page).to have_text(COPY::DELETE_SEARCH_DESCRIPTION)
          expect(page).to have_text(user_saved_search.name)
          find("button", text: "Delete").click
        end

        expect(page).to have_content("You have successfully deleted #{user_saved_search.name}")
        expect(page).to have_text("Viewing 0-0 of 0 total")
      end
    end
  end
end
