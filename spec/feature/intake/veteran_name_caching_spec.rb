# frozen_string_literal: true

feature "Higher-Level Review", :postgres do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ramp_start_date)

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_call_original
    allow_any_instance_of(Veteran).to receive(:bgs).and_return(bgs)
    allow(bgs).to receive(:fetch_veteran_info).and_call_original
  end

  let(:veteran) { create(:veteran, last_name: "Smith") }
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
        date: Time.zone.now.strftime("%m/%d/%Y")
      )

      step "name changes upstream" do
        Fakes::BGSService.edit_veteran_record(veteran.file_number, :last_name, "Changed")
      end

      click_intake_finish

      expect(page).to have_content("Intake completed")
    end

    step "EPs use the updated Veteran name" do
      veteran.reload

      expect(veteran.last_name).to eq("Changed")

      expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
        hash_including(veteran_hash: hash_including(last_name: "Changed"))
      )
    end
  end
end
