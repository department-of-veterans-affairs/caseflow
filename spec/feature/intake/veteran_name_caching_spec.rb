require "support/intake_helpers"

feature "Higher-Level Review" do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)

    Timecop.freeze(post_ramp_start_date)

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_call_original
    allow_any_instance_of(Veteran).to receive(:bgs).and_return(bgs)
    allow(bgs).to receive(:fetch_veteran_info).and_call_original
  end

  after do
    FeatureToggle.disable!(:intake)
    FeatureToggle.disable!(:intakeAma)
  end

  let(:veteran) { create(:veteran) }
  let(:bgs) { BGSService.new }

  scenario "Caseflow creates End Products with current upstream Veteran name" do
    step "start the intake" do
      start_higher_level_review(veteran)

      expect(veteran.last_name).to eq("Smith")
    end

    step "Add issue and complete intake" do
      visit "/intake/add_issues"

      expect(page).to have_content("Bob Smith")

      click_intake_add_issue
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "Description for Active Duty Adjustments",
        date: Time.zone.now.strftime("%D")
      )

      step "name changes upstream" do
        Fakes::BGSService.veteran_records[veteran.file_number][:last_name] = "Changed"
      end

      click_intake_finish

      expect(page).to have_content("Intake completed")
    end

    step "EPs use the updated Veteran name" do
      expect(bgs).to have_received(:fetch_veteran_info).exactly(5).times

      veteran.reload

      expect(veteran.last_name).to eq("Changed")

      expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
        hash_including(veteran_hash: hash_including(last_name: "Changed"))
      )
    end
  end
end
