require "rails_helper"

RSpec.feature "Intake Manager Page" do
  before do
    FeatureToggle.enable!(:intake)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 8, 8))

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
  end

  let(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  let(:issues) do
    [
      Generators::Issue.build
    ]
  end

  let(:inaccessible) { false }

  let!(:appeal) do
    Generators::Appeal.build(
      vbms_id: "12341234C",
      issues: issues,
      vacols_record: :ready_to_certify,
      veteran: veteran,
      inaccessible: inaccessible
    )
  end

  let!(:inactive_appeal) do
    Generators::Appeal.build(
      vbms_id: "77776666C",
      vacols_record: :full_grant_decided
    )
  end

  let!(:ineligible_appeal) do
    Generators::Appeal.build(
      vbms_id: "77778888C",
      vacols_record: :activated,
      issues: issues
    )
  end

  let(:ep_already_exists_error) do
    VBMS::HTTPError.new("500", "<faultstring>Claim not established. " \
      "A duplicate claim for this EP code already exists in CorpDB. Please " \
      "use a different EP code modifier. GUID: 13fcd</faultstring>")
  end

  let(:unknown_error) do
    VBMS::HTTPError.new("500", "<faultstring>Unknown</faultstring>")
  end

  scenario "User visits manager page" do
    visit "/intake/manage"
    expect(page).to have_content("Claims for manager review")
  end

  # To do
    Create fake data for:
    Each cancellation reason
    Each error
    successful ramp elections and ramp refilings (that succeeded on the first time)
    successful ramp elections and refilings that previously were canceled
    successful ramp elections and refilings that previously had errors

    invalid_file_number
    veteran_not_found
    veteran_not_accessible
    veteran_not_valid
    did_not_receive_ramp_election
    ramp_election_already_complete
    no_active_appeals
    no_eligible_appeals
    no_active_compensation_appeals
    no_active_fully_compensation_appeals
    no_complete_ramp_election
    ramp_election_is_active
    ramp_election_no_issues
    duplicate_intake_in_progress
    ramp_refiling_already_processed
    default



  scenario "Switching tab intervals" do
    User.authenticate!(roles: ["Admin Intake"])

    RampElection.create!(veteran_file_number: "77776661", notice_date: 1.day.ago)
    RampElection.create!(veteran_file_number: "77776662", notice_date: 1.day.ago)

    ramp_election = RampElection.create!(
      veteran_file_number: "77776663",
      notice_date: 7.days.ago,
      receipt_date: 45.minutes.ago,
      option_selected: :supplemental_claim,
      established_at: Time.zone.now,
      end_product_reference_id: "132",
      end_product_status: "VERY_ACTIVE"
    )
  end

  scenario "Unauthorized user access" do
    # Authenticated access without System Admin role
    User.authenticate!(roles: ["Mail Intake"])
    visit "/intake/manage"
    expect(page).to have_content("You aren't authorized")
  end
end
