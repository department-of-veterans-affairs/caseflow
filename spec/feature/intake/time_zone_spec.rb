# frozen_string_literal: true

feature "Appeal time zone", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(now_utc)
    BvaIntake.singleton.add_user(current_user)
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
    select_form(Constants.INTAKE_FORM_NAMES.appeal)
    safe_click ".cf-submit.usa-button"

    expect(page).to have_content(search_page_title)

    fill_in search_bar_title, with: veteran.file_number

    click_on "Search"
    expect(page).to have_current_path("/intake/review_request")

    fill_in "What is the Receipt Date of this form?", with: now_utc.to_date.mdY

    within_fieldset("Was this form submitted through VA.gov?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

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
    def browser_utc_offset
      evaluate_script("(new Date()).getTimezoneOffset()/60").to_s
    end

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
      # we can freeze the time on the server side, but not the browser side,
      # so the actual real time zone on the browser will shift between standard and daylight savings.
      expect((Time.zone.utc_offset / 3600) * -1).to eq(5)

      expect(browser_utc_offset).to match(/[45]/)
    end

    # Honolulu is as far from New York as New York is from UTC
    # and our browser is fixed at start time to New York.
    # So adjust the server the same number of hours forward, to mimic
    # what it's like for a browser in Honolulu time and server in New York.
    context "server time zone is 4/5 hours ahead of browser" do
      before do
        Time.zone = "UTC"
      end

      it "treats browser input dates as if they were in Eastern" do
        initiate_appeal_intake

        appeal = Appeal.last
        intake = Intake.last

        expect(appeal.receipt_date).to eq(now_localtime.to_date)
        expect(appeal.receipt_date).to eq(now_utc.to_date)
        expect(intake.started_at).to eq(now_localtime)
      end

      it "browser time zone is Eastern, server is UTC" do
        expect(browser_utc_offset).to match(/[45]/)
        expect(Time.zone.utc_offset).to eq 0
      end
    end
  end
end
