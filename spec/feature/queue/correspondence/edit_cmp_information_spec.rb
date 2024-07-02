# frozen_string_literal: true

# rubocop:disable Layout/LineLength
RSpec.feature("The Correspondence Review Package page") do
  let(:veteran) { create(:veteran) }
  let(:correspondence_documents) { create(:correspondence_document, correspondence: correspondence, document_file_number: veteran.file_number) }
  let(:mail_team_supervisor_user) { create(:inbound_ops_team_supervisor) }
  let(:mail_team_supervisor_org) { InboundOpsTeam.singleton }
  let(:inbound_ops_team_user) { create(:user) }
  let(:mail_team_org) { InboundOpsTeam.singleton }
  let(:current_user) { create(:inbound_ops_team_supervisor) }
  let!(:correspondence_type) { CorrespondenceType.create!(name: "a correspondence type.") }
  let(:correspondence) do
    create(
      :correspondence,
      veteran_id: veteran.id,
      uuid: SecureRandom.uuid
    )
  end

  context "Review package feature toggle" do
    before :each do
      # User.authenticate!(roles: ["Mail Intake"])
      FeatureToggle.enable!(:correspondence_queue)
      mail_team_org.add_user(inbound_ops_team_user)
      User.authenticate!(user: inbound_ops_team_user)
    end

    it "routes user to /under_construction if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
      expect(page).to have_current_path("/under_construction")
    end
  end

  context "Review package form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(user: current_user)
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
    end

    it "the Review package page exists" do
      expect(page).to have_current_path("/queue/correspondence/#{correspondence.uuid}/review_package")
    end

    it "the save button is disabled at first" do
      expect(page).to have_field("VA DOR")
      expect(page).to have_field("Package document type")
      expect(page).to have_button("Save", disabled: true)
    end

    it "Checking the VA DOR and Package document type values in modal" do
      expect(find_field("VA DOR").value).to eq correspondence.va_date_of_receipt.strftime("%Y-%m-%d")
      expect(find_field("Package document type").value).to have_content "NOD" || "Non-NOD"
    end

    it "displays request package action dropdown" do
      expect(page).to have_content("Request package action")
    end

    context "when request package action dropdown is clicked" do
      before do
        first(".cf-select__control").click
      end

      it "displays 4 package actions" do
        expect(page).to have_content("Reassign package")
        expect(page).to have_content("Remove package from Caseflow")
        expect(page).to have_content("Split package")
        expect(page).to have_content("Merge package")
      end

      context "when Reassign Package is selected" do
        before do
          find(:xpath, '//div[text()="Reassign package"]').click
        end

        it "modal opens with disabled confirm button" do
          expect(page).to have_content(
            "By confirming, you will send a request for the supervisor to take action on the following package:"
          )
          expect(page).to have_button("Confirm request", disabled: true)
        end

        it "providing a reason enables confirm button" do
          fill_in "Provide a reason for reassignment", with: "Reason for reassignment"
          expect(page).to have_button("Confirm request", disabled: false)
        end
      end

      context "when Merge Package is selected" do
        before do
          find(:xpath, '//div[text()="Merge package"]').click
        end

        it "modal opens with disabled confirm button" do
          expect(page).to have_content(
            "By confirming, you will send a request for the supervisor to take action on the following package:"
          )
          expect(page).to have_button("Confirm request", disabled: true)
        end

        it "selecting a reason enables confirm button" do
          page.all(".cf-form-radio-option > label")[1].click
          expect(page).to have_button("Confirm request", disabled: false)
          expect(page).not_to have_field("Reason for merge")
        end

        it "Selecting Other option should show instructions box to enter reason - enables confirm button" do
          page.all(".cf-form-radio-option > label")[2].click
          fill_in "Reason for merge", with: "Reason for merge"
          expect(page).to have_button("Confirm request", disabled: false)
        end
      end
    end
  end

  context "when request package action dropdown is clicked" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      mail_team_supervisor_org.add_user(mail_team_supervisor_user)
      User.authenticate!(user: mail_team_supervisor_user)
      @correspondence_uuid = "123456789"
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
    end

    it "Saving the VA DOR and Package document type values in modal" do
      fill_in "VA DOR", with: 6.days.ago.strftime("%m/%d/%Y")
      fill_in "Correspondence type", with: "a correspondence type."
      options = find_all("div", class: "cf-select__option", text: "a correspondence type.")
      options[1].click
      expect(page).to have_button("Save changes", disabled: false)
      click_button "Save changes"
      expect(page).to have_content("NOD")
    end
  end

  context "Checking VADOR field is enable for InboundOpsTeam" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      mail_team_supervisor_org.add_user(mail_team_supervisor_user)
      User.authenticate!(user: mail_team_supervisor_user)
      @correspondence_uuid = "123456789"
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
    end

    it "Checking VADOR field is enabled for Mail Supervisor" do
      expect(page).to have_field("VA DOR", readonly: false)
    end
  end

  context "Checking VADOR field is disabled for General mail user" do
    before do
      FeatureToggle.enable!(:correspondence_queue)
      mail_team_org.add_user(inbound_ops_team_user)
      User.authenticate!(user: inbound_ops_team_user)
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
    end

    it "Checking VADOR field is disabled for General mail user" do
      expect(page).to have_field("VA DOR", readonly: true)
    end
  end
end

# rubocop:enable Layout/LineLength
