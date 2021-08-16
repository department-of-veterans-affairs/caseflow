# frozen_string_literal: true

RSpec.feature "Pre-Docket intakes", :all_dbs do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:vha_predocket_appeals)
    BvaIntake.singleton.add_user(bva_intake_user)
  end
  after { FeatureToggle.disable!(:vha_predocket_appeals) }

  let(:bva_intake_user) { create(:intake_user) }
  let(:veteran) { create(:veteran) }

  context "as a BVA Intake user" do
    before { User.authenticate!(user: bva_intake_user) }

    it "intaking VHA issues creates pre-docket task instead of regular docketing tasks" do
      start_appeal(veteran, intake_user: bva_intake_user)
      visit "/intake"

      expect(page).to have_current_path("/intake/review_request")

      click_intake_continue

      expect(page).to have_content("Add / Remove Issues")

      click_intake_add_issue
      add_intake_nonrating_issue(
        benefit_type: "Veterans Health Administration",
        category: "Caregiver",
        description: "I am a VHA issue",
        date: 1.month.ago.mdY
      )
      click_intake_finish

      expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")

      appeal = Appeal.last

      visit "/queue/appeals/#{appeal.external_id}"

      expect(page).to have_content("Pre Docket Task")

      created_task_types = Set.new(appeal.tasks.map(&:type))
      pre_docket_tasks = Set.new %w[RootTask PreDocketTask]
      docket_tasks = Set.new %w[
        DistributionTask
        TrackVeteranTask
        InformalHearingPresentationTask
        EvidenceSubmissionWindowTask
        TranslationTask
      ]

      expect(pre_docket_tasks.subset?(created_task_types)).to be true
      expect(docket_tasks.subset?(created_task_types)).to be false
    end
  end
end
