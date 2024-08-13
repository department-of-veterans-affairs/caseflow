# frozen_string_literal: true

RSpec.feature("The Correspondence Details Response Letters page") do
  include CorrespondenceHelpers
  include CorrespondenceTaskHelpers

  let(:organization) { InboundOpsTeam.singleton }
  let(:mail_user) { User.authenticate!(roles: ["Mail Team"]) }
  let(:correspondence) { create :correspondence }
  let(:correspondence_intake_task) do
    create(
      :correspondence_intake_task,
      appeal: correspondence,
      appeal_type: Correspondence.name,
      assigned_to: mail_user
    )
  end

  before do
    # reload in case of controller validation triggers before data created
    correspondence_intake_task.reload
    organization.add_user(mail_user)
    mail_user.reload
  end

  context "intake form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      visit "/queue/correspondence/#{correspondence.uuid}/intake"
    end

    it "the intake page exists" do
      expect(page).to have_current_path("/queue/correspondence/#{correspondence.uuid}/intake")
    end

    it "Create Response letter" do
      click_on("+ Add letter")
      expect(page).to have_field("Date sent")
      mydate = page.all("#date-set")
      expect(mydate[0].value == Time.zone.today.strftime("%Y-%m-%d"))
    end
  end

end
