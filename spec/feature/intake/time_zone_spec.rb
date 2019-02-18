require "support/intake_helpers"

feature "Appeal time zone" do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:intake_legacy_opt_in)

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

  let(:now_localtime) { Time.new(2019, 2, 14, 0, 0, 0).in_time_zone }
  let(:now_utc) { now_localtime.utc }

  let!(:veteran) { create(:veteran) }

  # rubocop:disable Metrics/AbcSize
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

    fill_in "What is the Receipt Date of this form?", with: now_utc.to_date.mdY

    within_fieldset("Which review option did the Veteran request?") do
      find("label", text: "Evidence Submission", match: :prefer_exact).click
    end

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    select_agree_to_withdraw_legacy_issues(false)
    click_intake_continue

    expect(page).to have_current_path("/intake/add_issues")
  end
  # rubocop:enable Metrics/AbcSize

  describe "browser to server" do
    it "writes all times in UTC" do
      expect(now_localtime.iso8601).to_not eq(now_utc.iso8601)
      expect(now_localtime.to_date).to eq(now_utc.to_date)
      expect(now_localtime.to_date.mdY).to eq("02/14/2019")
      expect(now_utc.to_date.mdY).to eq("02/14/2019")

      initiate_appeal_intake

      appeal = Appeal.last
      intake = Intake.last

      expect(appeal.receipt_date).to eq(now_localtime.to_date)
      expect(appeal.receipt_date).to eq(now_utc.to_date)
      expect(intake.started_at).to eq(now_localtime)
    end

    it "browser time zone is the same as server (tests only)" do
      browser_utc_offset = evaluate_script("(new Date()).getTimezoneOffset()/60")
      expect(browser_utc_offset).to eq((Time.zone.utc_offset / 3600) * -1)
    end
  end
end
