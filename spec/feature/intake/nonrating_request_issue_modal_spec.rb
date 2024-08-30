# frozen_string_literal: true

require "json"

ISSUE_CATEGORIES = JSON.parse(File.read(Rails.root.join("client", "constants", "ISSUE_CATEGORIES.json")))

feature "Nonrating Request Issue Modal", :postgres do
  include IntakeHelpers

  let(:bva_intake) { BvaIntake.singleton }
  let(:bva_intake_admin_user) { create(:user, roles: ["Mail Intake"]) }

  before do
    Timecop.freeze(post_ama_start_date)
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
    User.authenticate!(user: bva_intake_admin_user)
    FeatureToggle.enable!(:mst_identification)
    FeatureToggle.enable!(:pact_identification)
    FeatureToggle.disable!(:disable_ama_eventing)
  end

  after do
    FeatureToggle.disable!(:mst_identification)
    FeatureToggle.disable!(:pact_identification)
    FeatureToggle.enable!(:disable_ama_eventing)
  end

  let(:veteran_file_number) { "123412345" }
  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number, first_name: "Ed", last_name: "Merica")
  end

  def check_for_mst_pact
    expect(page).to have_content("Military Sexual Trauma (MST)")
    expect(page).to have_content("PACT Act")
  end

  def check_for_no_mst_pact
    expect(page).to_not have_content("Military Sexual Trauma (MST)")
    expect(page).to_not have_content("PACT Act")
  end

  # rubocop:disable Metrics/ParameterLists
  # rubocop:disable Metrics/AbcSize
  def add_intake_for_nonrating_issue(
    benefit_type: "Compensation",
    category: "Active Duty Adjustments",
    description: "Some description",
    date: "01/01/2016",
    legacy_issues: false,
    is_predocket_needed: false
  )
    add_button_text = legacy_issues ? "Next" : "Add this issue"
    expect(page.text).to match(/Does issue \d+ match any of these non-rating issue categories?/)
    expect(page).to have_button(add_button_text, disabled: true)

    # has_css will wait 5 seconds by default, and we want an instant decision.
    # we can trust the modal is rendered because of the expect() calls above.
    if page.has_css?("#issue-benefit-type", wait: 0)
      fill_in "Benefit type", with: benefit_type
      find("#issue-benefit-type").send_keys :enter
    end

    if page.has_css?("div.cf-is-predocket-needed", wait: 1)
      within_fieldset("Is pre-docketing needed for this issue?") do
        find("label", text: is_predocket_needed ? "Yes" : "No", match: :prefer_exact).click
      end
    end

    fill_in "Issue category", with: category
    find("#issue-category").send_keys :enter
    unless page.has_selector?("label", text: "Issue description", visible: true)
      find("label", text: "None of these match").click
    end
    fill_in "Issue description", with: description
    fill_in "Decision date", with: date
    expect(page).to have_button(add_button_text, disabled: false)
    safe_click ".add-issue"
  end
  # rubocop:enable Metrics/ParameterLists
  # rubocop:enable Metrics/AbcSize

  def test_issue_categories(decision_review_type:, benefit_type:, included_categories:, mst_pact:)
    case decision_review_type
    when "higher_level_review"
      start_higher_level_review(
        veteran,
        benefit_type: benefit_type
      )
    when "supplemental_claim"
      start_supplemental_claim(
        veteran,
        benefit_type: benefit_type
      )
    when "appeal"
      start_appeal(veteran)
    end

    visit_and_test_categories(included_categories, benefit_type, mst_pact)
  end

  def visit_and_test_categories(included_categories, benefit_type, mst_pact)
    visit "/intake"
    click_intake_continue
    click_intake_add_issue
    mst_pact ? check_for_mst_pact : check_for_no_mst_pact
    click_intake_nonrating_category_dropdown

    included_categories.each do |category|
      expect(page).to have_content(category)
    end

    add_intake_for_nonrating_issue(
      category: included_categories.first,
      description: "I am a description",
      date: Time.zone.today.mdY
    )

    click_intake_finish
    expect(page).to have_content("Intake completed") if %w[compensation pension].include?(benefit_type)

    # hesitate just a little so non-comp background tasks can finish.
    sleep 1

    expect(RequestIssue.find_by(
             nonrating_issue_category: included_categories.first
           )).to_not be_nil
  end

  context "when it is a claim review" do
    it "Shows the correct issue categories by benefit type" do
      test_issue_categories(
        decision_review_type: "higher_level_review",
        benefit_type: "pension",
        included_categories: ISSUE_CATEGORIES["pension"],
        mst_pact: false
      )

      test_issue_categories(
        decision_review_type: "higher_level_review",
        benefit_type: "vha",
        included_categories: ISSUE_CATEGORIES["vha"],
        mst_pact: false
      )

      test_issue_categories(
        decision_review_type: "supplemental_claim",
        benefit_type: "fiduciary",
        included_categories: ISSUE_CATEGORIES["fiduciary"],
        mst_pact: false
      )
    end
  end

  context "when the decision review type is appeal" do
    it "should show the compensation categories because there is no benefit type" do
      test_issue_categories(
        decision_review_type: "appeal",
        benefit_type: "not applicable to appeal",
        included_categories: ["Unknown Issue Category"],
        mst_pact: true
      )
    end
  end
end
