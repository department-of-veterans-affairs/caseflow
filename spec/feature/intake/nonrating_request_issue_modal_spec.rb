# frozen_string_literal: true

feature "Nonrating Request Issue Modal", :postgres do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)
  end

  let(:veteran_file_number) { "123412345" }
  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number, first_name: "Ed", last_name: "Merica")
  end

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

    visit_and_test_categories(included_category, excluded_category, benefit_type)
  end

  def visit_and_test_categories(included_category, excluded_category, benefit_type)
    visit "/intake"
    click_intake_continue
    click_intake_add_issue
    click_intake_nonrating_category_dropdown
    expect(page).to have_content(included_category)
    expect(page).to_not have_content(excluded_category)
    add_intake_nonrating_issue(
      category: included_category,
      description: "I am a description",
      date: Time.zone.today.mdY
    )
    click_intake_finish

    expect(page).to have_content("Intake completed") if %w[compensation pension].include?(benefit_type)

    # hesitate just a little so non-comp background tasks can finish.
    sleep 1

    expect(RequestIssue.find_by(
             nonrating_issue_category: included_category
           )).to_not be_nil
  end

  context "when it is a claim review" do
    it "Shows the correct issue categories by benefit type" do
      test_issue_categories(
        decision_review_type: "higher_level_review",
        benefit_type: "pension",
        included_category: "Eligibility | Wartime Service",
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
