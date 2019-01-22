require "support/intake_helpers"

feature "Appeal time zone" do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:intake_legacy_opt_in)

    Time.zone = "America/New_York"
    Timecop.freeze(now_utc)
  end

  after do
    FeatureToggle.disable!(:intake)
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:intake_legacy_opt_in)
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:now_localtime) { Time.new(2018, 11, 2, 0, 0, 0).in_time_zone }
  let(:now_utc) { now_localtime.utc }

  let!(:veteran) { create(:veteran) }

  def initiate_appeal_intake
    visit "/intake"
    safe_click ".Select"

    fill_in "Which form are you processing?", with: Constants.INTAKE_FORM_NAMES.appeal
    find("#form-select").send_keys :enter

    safe_click ".cf-submit.usa-button"

    expect(page).to have_content(search_page_title)

    fill_in search_bar_title, with: veteran.file_number

    click_on "Search"
    expect(page).to have_current_path("/intake/review_request")

    fill_in "What is the Receipt Date of this form?", with: now_utc.strftime("%D")

    within_fieldset("Which review option did the Veteran request?") do
      find("label", text: "Evidence Submission", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    within_fieldset("Did they agree to withdraw their issues from the legacy system?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    binding.pry

    click_intake_continue

    expect(page).to have_current_path("/intake/add_issues")
  end

  describe "browser to server" do
    it "writes all times in UTC" do
      binding.pry

      expect(now_localtime.to_date.to_s).to eq("2018-11-01")
      expect(now_utc.to_date.to_s).to eq("2018-11-02")
      
      initiate_appeal_intake

      binding.pry

      appeal = Appeal.last
      intake = Intake.last

    end

    it "displays all times in browser time zone" do

    end
  end
end
