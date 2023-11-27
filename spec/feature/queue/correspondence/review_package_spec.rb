# frozen_string_literal: true

RSpec.feature("The Correspondence Review Pacakage page") do
  let(:veteran) { create(:veteran) }
  let(:package_document_type) { PackageDocumentType.create(id: 15, active: true, created_at: Time.zone.now, name: 10_182, updated_at: Time.zone.now) }
  let(:correspondence) { create(:correspondence, veteran_id: veteran.id, package_document_type_id: package_document_type.id) }
  let(:correspondence_documents) { create(:correspondence_document, correspondence: correspondence, document_file_number: veteran.file_number) }
  let(:mail_team_user) { create(:user) }
  let(:mail_team_org) { MailTeam.singleton }

  context "Review package feature toggle" do
    before :each do
      User.authenticate!(roles: ["Mail Intake"])
    end

    it "routes user to /unauthorized if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
      expect(page).to have_current_path("/unauthorized")
    end

    it "routes to intake if feature toggle is enabled" do
      FeatureToggle.enable!(:correspondence_queue)
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
      expect(page).to have_current_path("/queue/correspondence/#{correspondence.uuid}/review_package")
    end
  end

  context "Review package form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
    end

    it "the Review package page exists" do
      expect(page).to have_current_path("/queue/correspondence/#{correspondence.uuid}/review_package")
      expect(page).to have_content(COPY::CORRESPONDENCE_REVIEW_PACKAGE_TITLE)
    end

    it "check for CMP Edit button" do
      expect(page).to have_button("Edit")
      expect(page).to have_button("Cancel")
      expect(page).to have_button("Create record")
    end

    it "Intake appeal button should be hidden for document type 10182" do
      if package_document_type.name.to_s == "10182"
        expect(page).to have_content("Intake appeal")
      else
        expect(page).to_not have_content("Intake appeal")
      end
    end
  end
end
