# frozen_string_literal: true

RSpec.feature "SwitchApps", :postgres do
  context "A user with just Queue access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Reader"]))
    end

    before do
      visit "/queue"
    end

    scenario "doesn't see switch product dropdown" do
      expect(page).to_not have_content("Switch product")
    end
  end

  context "A user with Queue and Hearings access" do
    let!(:user) do
      User.authenticate!(user: create(:user, roles: ["Reader", "Build HearSched"]))
    end

    before do
      visit "/queue"
    end

    scenario "sees switch product dropdown" do
      expect(page).to have_link("Switch product", href: "#Switch product", exact: true)
    end

    context "with the options" do
      before do
        find("a", text: "Switch product").click
      end

      scenario "queue" do
        expect(page).to have_link(
          queue_and_hearings_user_links[0][:title], href: queue_and_hearings_user_links[0][:link], exact: true
        )
      end

      scenario "hearings" do
        expect(page).to have_link(
          queue_and_hearings_user_links[1][:title], href: queue_and_hearings_user_links[1][:link], exact: true
        )
      end

      scenario "and can navigate to queue" do
        find("a", text: queue_and_hearings_user_links[0][:title]).click
        expect(page).to have_content(COPY::USER_QUEUE_PAGE_TABLE_TITLE)
      end

      scenario "and can navigate to hearing schedule" do
        find("a", text: queue_and_hearings_user_links[1][:title]).click
        expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
      end
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
      visit "/decision_reviews/#{vha_business_line.url}"
    end

    scenario "see's the switch product dropdown menu" do
      expect(page).to have_link("Switch product", href: "#Switch product", exact: true)
    end

    context "with the options" do
      before do
        find("a", text: "Switch product").click
      end

      scenario "Intake" do
        expect(page).to have_link(vha_user_links[0][:title], href: vha_user_links[0][:link], exact: true)
      end

      scenario "Decision Reviews Queue" do
        expect(page).to have_link(vha_user_links[1][:title], href: vha_user_links[1][:link], exact: true)
      end

      scenario "Queue" do
        expect(page).to have_link(vha_user_links[2][:title], href: vha_user_links[2][:link], exact: true)
      end
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

  def check_for_links(link_hashes = vha_user_links)
    link_hashes.each do |link_hash|
      expect(page).to have_link(link_hash[:title], href: link_hash[:link])
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
      }
    ]
  end
end
