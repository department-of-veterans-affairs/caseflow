# frozen_string_literal: true

feature "Decision Review Task Page", :postgres do
  before do
    User.stub = user
    vha_org.add_user(user)
    Timecop.travel(Time.zone.local(2023, 0o2, 0o1))
    FeatureToggle.enable!(:decision_review_queue_ssn_column)
  end

  after do
    FeatureToggle.disable!(:decision_review_queue_ssn_column)
    Timecop.return
  end

  let!(:vha_org) { create(:business_line, name: "Veterans Health Administration", url: "vha") }
  let(:user) { create(:default_user) }
  let(:veteran) { create(:veteran) }
  let(:decision_date) { Time.zone.now + 10.days }

  let!(:in_progress_task) do
    create(:higher_level_review, :with_vha_issue, :create_business_line, benefit_type: "vha", veteran: veteran)
  end

  let(:business_line_url) { "decision_reviews/vha" }
  let(:dispositions_url) { "#{business_line_url}/tasks/#{in_progress_task.id}" }

  it "vha decision Review workflow" do
    step "submit button should be disabled and cancel returns back to business line" do
      visit dispositions_url
      expect(page).to have_button("Complete", disabled: true)
      click_on "Cancel"
      expect(page).to have_current_path("/#{business_line_url}", ignore_query: true)
    end

    step "completing a task should redirect to completed task tab" do
      visit dispositions_url
      fill_in "decision-date", with: decision_date.strftime("%m/%d/%Y")
      page.find("div.cf-select").click
      page.find("div.cf-select__menu").find("div", exact_text: "Granted").click

      description = page.find("textarea")
      description.fill_in with: "granted"

      scroll_to(page, align: :bottom)

      expect(page).to have_button("Complete", disabled: false)
      click_button("Complete")
      expect(page).to have_current_path("/#{business_line_url}?tab=completed&page=1")
    end

    step "completed Decision review task should have specific decision date provided during completion" do
      visit dispositions_url
      expect(page).to have_selector("h1", text: "Veterans Health Administration")
      expect(page).to have_content(veteran.name)
      expect(page.find("textarea").disabled?).to be true

      disposition_dropdown = page.find("div.cf-select")
      expect(disposition_dropdown).to have_content("Granted")
      expect(disposition_dropdown).to have_css(".cf-select--is-disabled")
      expect(page).to have_text(COPY::DISPOSITION_DECISION_DATE_LABEL)
      expect(page.find_by_id("decision-date").value).to have_content(decision_date.strftime("%Y-%m-%d"))
    end
  end
end
