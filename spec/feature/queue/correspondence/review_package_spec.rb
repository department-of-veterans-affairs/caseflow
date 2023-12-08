# frozen_string_literal: true

# rubocop:disable Layout/LineLength
RSpec.feature("The Correspondence Review Package page") do
  let(:veteran) { create(:veteran) }
  let(:package_document_type) { PackageDocumentType.create(id: 15, active: true, created_at: Time.zone.now, name: "10182", updated_at: Time.zone.now) }
  let(:correspondence) { create(:correspondence, :with_single_doc, veteran_id: veteran.id, package_document_type_id: package_document_type.id) }
  let(:mail_team_user) { create(:user, roles: ["Mail Intake"]) }
  let(:mail_team_org) { MailTeam.singleton }

  context "Review package feature toggle" do
    before :each do
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
    end

    it "routes user to /unauthorized if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence/#{@correspondence_uuid}/review_package"
      expect(page).to have_current_path("/unauthorized")
    end

    it "routes to intake if feature toggle is enabled" do
      FeatureToggle.enable!(:correspondence_queue)
      visit "/queue/correspondence/#{@correspondence_uuid}/review_package"
      expect(page).to have_current_path("/queue/correspondence/#{@correspondence_uuid}/review_package")
    end
  end

  context "Review package form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
      visit "/queue/correspondence/#{@correspondence_uuid}/review_package"
    end

    it "the Review package page exists" do
      expect(page).to have_current_path("/queue/correspondence/#{@correspondence_uuid}/review_package")
    end
  end

  context "Review package - intake appeal" do
    let(:non_10182_package_type) { PackageDocumentType.create(id: 1, active: true, name: "0304") }
    let(:correspondence_2) { create(:correspondence, :with_single_doc, veteran_id: veteran.id, package_document_type_id: non_10182_package_type.id) }

    before do
      FeatureToggle.enable!(:correspondence_queue)
      mail_team_org.add_user(mail_team_user)
      User.authenticate!(user: mail_team_user)
    end

    it "completes step 1 and 2 then goes to step 3 of intake appeal process" do
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
      click_button "Intake appeal"
      expect(page).to have_current_path("/intake/review_request")
      expect(page).to have_text `#{veteran.file_number}`
      expect(page).to have_text `Review #{veteran.first_name} #{veteran.last_name}'s Decision Review Request: Board Appeal (Notice of Disagreement) - VA Form 10182`
    end
  end
end
# rubocop:enable Layout/LineLength
