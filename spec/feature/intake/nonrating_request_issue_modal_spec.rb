require "support/intake_helpers"

feature "Nonrating Request Issue Modal" do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    Timecop.freeze(Time.utc(2018, 11, 28))
  end

  after do
    FeatureToggle.disable!(:intakeAma)
  end

  let(:veteran_file_number) { "123412345" }
  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number, first_name: "Ed", last_name: "Merica")
  end
  # rubocop: disable Metrics/MethodLength
  def test_issue_categories(decision_review_type:, benefit_type:, included_category:, excluded_category:)
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

    visit "/intake"
    click_intake_continue
    click_intake_add_issue
    safe_click ".Select-placeholder"
    expect(page).to have_content(included_category)
    expect(page).to_not have_content(excluded_category)
    add_intake_nonrating_issue(
      category: included_category,
      description: "I am a description",
      date: "04/19/2018"
    )
    click_intake_finish
    expect(page).to have_content("Intake completed")
    expect(RequestIssue.find_by(
             issue_category: included_category
    )).to_not be_nil
  end
  # rubocop: enable Metrics/MethodLength

  context "when it is a claim review" do
    it "Shows the correct issue categories by benefit type" do
      test_issue_categories(
        decision_review_type: "higher_level_review",
        benefit_type: "pension",
        included_category: "Eligibility | Wartime service",
        excluded_category: "Entitlement to Services"
      )

      test_issue_categories(
        decision_review_type: "higher_level_review",
        benefit_type: "vha",
        included_category: "Eligibility for Treatment | Dental",
        excluded_category: "Entitlement to Services"
      )

      test_issue_categories(
        decision_review_type: "supplemental_claim",
        benefit_type: "fiduciary",
        included_category: "Appointment of a Fiduciary (38 CFR 13.100)",
        excluded_category: "Entitlement to Services"
      )
    end
  end

  context "when the decision review type is appeal" do
    it "should show the compensation categories because there is no benefit type" do
      test_issue_categories(
        decision_review_type: "appeal",
        benefit_type: "not applicable to appeal",
        included_category: "Apportionment",
        excluded_category: "Entitlement to Services"
      )
    end
  end
end
