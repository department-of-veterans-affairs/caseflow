require "rails_helper"
require "support/intake_helpers"

RSpec.feature "Nonrating Request Issue Modal" do
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

  def test_issue_categories(benefit_type:, first_category:, second_category:)
    start_higher_level_review(
      veteran,
      benefit_type: benefit_type
    )
    visit "/intake"
    click_intake_continue
    click_intake_add_issue
    safe_click ".Select-placeholder"
    expect(page).to have_content(first_category)
    expect(page).to have_content(second_category)
    add_intake_nonrating_issue(
      category: first_category,
      description: "I am a description",
      date: "04/19/2018"
    )
    click_intake_finish
    expect(page).to have_content("Intake completed")
    expect(RequestIssue.find_by(
             issue_category: first_category
    )).to_not be_nil
  end

  it "Shows the correct issue categories by benefit type" do
    test_issue_categories(
      benefit_type: "compensation",
      first_category: "Apportionment",
      second_category: "Incarceration Adjustments"
    )

    test_issue_categories(
      benefit_type: "pension",
      first_category: "Eligibility | Wartime service",
      second_category: "Burial Benefits - VA Hospitalization Death"
    )

    test_issue_categories(
      benefit_type: "vha",
      first_category: "Eligibility for Treatment | Dental",
      second_category: "Other"
    )
  end
end
