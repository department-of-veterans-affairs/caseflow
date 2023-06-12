# frozen_string_literal: true

RSpec.feature "SwitchApps", :postgres do
  context "User with just Queue access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Reader"]))
    end

    before do
      visit "/queue"
    end

    scenario "doesn't see the Switch product dropdown" do
      expect(page).to_not have_content("Switch product")
    end
  end

  context "User with Queue and Hearings access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Reader", "Build HearSched"]))
    end

    before do
      visit "/queue"
    end

    scenario "sees the Switch product dropdown menu with the options Queue and Hearings" do
      expect(page).to have_link("Switch product", href: "#Switch product", exact: true)

      find("a", text: "Switch product").click
      expect(page).to have_link(
        queue_and_hearings_user_links[0][:title], href: queue_and_hearings_user_links[0][:link], exact: true
      )
      expect(page).to have_link(
        queue_and_hearings_user_links[1][:title], href: queue_and_hearings_user_links[1][:link], exact: true
      )
    end

    scenario "doesn't have the options Intake or VHA Decision Review Queue" do
      find("a", text: "Switch product").click
      expect(page).not_to have_link(vha_user_links[0][:title], href: vha_user_links[0][:link])
      expect(page).not_to have_link(vha_user_links[1][:title], href: vha_user_links[1][:link])
    end

    scenario "can navigate to Hearing schedule and Queue pages" do
      find("a", text: "Switch product").click
      find("a", text: queue_and_hearings_user_links[1][:title]).click
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)

      find("a", text: "Switch product").click
      find("a", text: queue_and_hearings_user_links[0][:title]).click
      expect(page).to have_content(COPY::USER_QUEUE_PAGE_TABLE_TITLE)
    end
  end

  context "User with VHA access" do
    let(:roles) { ["Mail Intake", "Build HearSched"] }
    let!(:user) do
      User.authenticate!(user: create(:user, roles: roles))
    end

    let!(:vha_business_line) do
      create(:business_line, url: "vha", name: "Veterans Health Administration")
    end

    let!(:list_order) do
      ["Caseflow Intake",
       "VHA Decision Review Queue",
       "Caseflow Queue",
       "Caseflow Search cases",
       "Caseflow Hearings"]
    end

    before do
      vha_business_line.add_user(user)
      visit "/decision_reviews/#{vha_business_line.url}"
    end

    scenario "sees the Switch product dropdown menu with the options
    Intake, VHA Decision Reviews Queue, Queue and search" do
      expect(page).to have_link("Switch product", href: "#Switch product", exact: true)

      find("a", text: "Switch product").click
      expect(page).to have_link(vha_user_links[0][:title], href: vha_user_links[0][:link], exact: true)
      expect(page).to have_link(vha_user_links[1][:title], href: vha_user_links[1][:link], exact: true)
      expect(page).to have_link(vha_user_links[2][:title], href: vha_user_links[2][:link], exact: true)
      expect(page).to have_link(vha_user_links[3][:title], href: vha_user_links[3][:link], exact: true)
    end

    scenario "can navigate to the VHA Decision Reviews Queue" do
      find("a", text: "Switch product").click
      find("a", text: vha_user_links[1][:title]).click
      expect(page).to have_content(vha_business_line.name)
    end

    scenario "can navigate to different links" do
      vha_user_links.each do |item|
        find("a", text: "Switch product").click
        find("a", text: item[:title]).click
        expect(current_url).to have_content(item[:link])
      end
    end

    it "should match the order in the dropdown" do
      visit "/intake"
      find("a", text: "Switch product").click
      dropdown_menu_text = page.find(".cf-dropdown-menu").text
      expect(dropdown_menu_text.split("\n")).to eq(list_order)
    end

    it "VHA user with roles 'Case details' should not have queue link in the dropdown" do
      user.update(roles: roles << "Case Details")
      visit "/decision_reviews/#{vha_business_line.url}"
      expect(page).to have_content("Switch product")
      find("a", text: "Switch product").click
      dropdown_menu_options = page.find(".cf-dropdown-menu").text
      expect(dropdown_menu_options.split("\n")).to eq(list_order - ["Caseflow Queue"])
    end
  end

  context "User without VHA access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Mail Intake"]))
    end
    let!(:vha_business_line) do
      create(:business_line, url: "vha", name: "Veterans Health Administration")
    end

    scenario "doesn't have access to VHA Decision Review Queue" do
      visit "/decision_reviews/#{vha_business_line.url}"
      expect(page).to have_current_path("/unauthorized", ignore_query: true)
      expect(page).to_not have_content("Switch product")
    end
  end

  def queue_and_hearings_user_links
    [
      {
        title: "Caseflow Queue",
        link: "/queue"
      },
      {
        title: "Caseflow Hearings",
        link: "/hearings/schedule"
      }
    ]
  end

  def vha_user_links
    [
      {
        title: "Caseflow Intake",
        link: "/intake"
      },
      {
        title: "VHA Decision Review Queue",
        link: "/decision_reviews/vha"
      },
      {
        title: "Caseflow Queue",
        link: "/queue"
      },
      {
        title: "Caseflow Search cases",
        link: "/search"
      }
    ]
  end
end
