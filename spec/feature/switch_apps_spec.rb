# frozen_string_literal: true

RSpec.feature "SwitchApps", :postgres do
  context "A user with just Queue access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Reader"]))
    end

    scenario "doesn't see switch product dropdown" do
      visit "/queue"

      expect(page).to have_content("Queue")
      expect(page).to_not have_content("Switch product")
    end
  end

  context "A user with Queue and Hearings access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Reader", "Build HearSched"]))
    end

    scenario "sees switch product dropdown and can navigate to hearing schedule" do
      visit "/queue"

      expect(page).to have_content("Queue")

      find("a", text: "Switch product").click
      find("a", text: "Caseflow Hearings").click

      expect(page).to have_content("Welcome to Caseflow Hearings!")
    end
  end

  context "A user with VHA access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Mail Intake"]))
    end

    let!(:vha_business_line) do
      create(:business_line, url: "vha", name: "Veterans Health Administration")
    end

    before do
      vha_business_line.add_user(user)
    end

    scenario "currently sees switch product dropdown with only queue and and intake" do
      visit "/decision_reviews/#{vha_business_line.url}"
      expect(page).to have_current_path("/decision_reviews/#{vha_business_line.url}", ignore_query: true)
      find("a", text: "Switch product").click
      check_for_links
    end
  end

  context "A user with no-VHA access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Mail Intake"]))
    end
    let!(:vha_business_line) do
      create(:business_line, url: "vha", name: "Veterans Health Administration")
    end

    scenario "Non-VHA user doesn't have access to decision review vha" do
      visit "/decision_reviews/#{vha_business_line.url}"
      expect(page).to have_current_path("/unauthorized", ignore_query: true)
      expect(page).to_not have_content("Switch product")
    end
  end

  def check_for_links(link_hashes = all_vha_links)
    link_hashes.each do |link_hash|
      expect(page).to have_link(link_hash[:title], href: link_hash[:link])
    end
  end

  def all_vha_links
    [
      {
        title: "Caseflow Intake",
        link: "/intake"
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
