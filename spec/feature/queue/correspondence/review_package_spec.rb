# frozen_string_literal: true

# rubocop:disable Layout/LineLength
RSpec.feature("The Correspondence Review Package page") do
  let(:veteran) { create(:veteran) }
  let(:package_document_type) { PackageDocumentType.create(id: 15, active: true, created_at: Time.zone.now, name: "10182", updated_at: Time.zone.now) }
  let(:correspondence) { create(:correspondence, :with_single_doc, veteran_id: veteran.id, package_document_type_id: package_document_type.id) }
  let(:mail_team_supervisor_user) { create(:user, roles: ["Mail Intake"]) }
  let(:mail_team_supervisor_org) { MailTeamSupervisor.singleton }

  context "Review package feature toggle" do
    before :each do
      mail_team_supervisor_org.add_user(mail_team_supervisor_user)
      User.authenticate!(user: mail_team_supervisor_user)
      @correspondence_uuid = "123456789"
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
      mail_team_supervisor_org.add_user(mail_team_supervisor_user)
      User.authenticate!(user: mail_team_supervisor_user)
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

    context "when remove package task is pending review" do
      let(:review_package_task) { ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name) }

      before do
        task_params = {
          parent_id: review_package_task.id,
          instructions: ["test remove", "test"],
          assigned_to: MailTeamSupervisor.singleton,
          appeal_id: correspondence.id,
          appeal_type: "Correspondence",
          status: Constants.TASK_STATUSES.assigned,
          type: "RemovePackageTask"
        }
        ReviewPackageTask.create_from_params(task_params, mail_team_supervisor_user)
        review_package_task.update!(assigned_to: MailTeamSupervisor.singleton, status: :on_hold)
        visit "/queue/correspondence/#{correspondence.uuid}/review_package"
      end

      it "page is readOnly " do
        expect(page).to have_button("Edit", disabled: true)
        expect(page).to have_field("Veteran file number", readonly: true)
        expect(page).to have_field("Veteran name", readonly: true)
        expect(page).to have_field("Notes", disabled: true)
        expect(find(".cf-form-dropdown")).to have_css("div.cf-select--is-disabled")
        expect(page).to have_button("Review removal request")
      end

      it "request package action dropdown isn't visible" do
        expect(page).to have_no_content("Request pacakge action")
      end

      it "warning banner appears" do
        expect(page).to have_content("This package has a pending request")
      end

      it "open Modal to remove Package" do
        expect(page).to have_button("Review removal request")
        click_button "Review removal request"
        radio_choices = page.all(".cf-form-radio-option > label")
        expect(radio_choices[0]).to have_content("Approve request")
        expect(radio_choices[1]).to have_content("Reject request")
        expect(page).to have_button("Cancel")
        expect(page).to have_button("Confirm", disabled: true)
        expect(page).not_to have_field("Provide a reason for rejection")
      end

      it "fill Modal to remove Package up" do
        expect(page).to have_button("Review removal request")
        click_button "Review removal request"
        page.all(".cf-form-radio-option > label")[0].click
        expect(page).to have_field("Provide a reason for rejection")
        expect(page).to have_button("Confirm", disabled: true)

        fill_in "Provide a reason for rejection", with: "Provide a reason for rejection"
        expect(page).to have_button("Confirm", disabled: false)
      end

      it "remove Package" do
        expect(page).to have_button("Review removal request")
        click_button "Review removal request"
        page.all(".cf-form-radio-option > label")[1].click
        expect(page).to have_field("Provide a reason for rejection")
        expect(page).to have_button("Confirm", disabled: true)

        fill_in "Provide a reason for rejection", with: "Provide a reason for rejection"
        expect(page).to have_button("Confirm", disabled: false)
        click_button("Confirm")
        using_wait_time(10) do
          expect(page).to have_content("The package has been removed from Caseflow and must be manually uploaded again from the Centralized Mail Portal, if it needs to be processed.")
        end
      end
    end
  end

  context "Review package - intake appeal" do
    let(:non_10182_package_type) { PackageDocumentType.create(id: 1, active: true, name: "0304") }
    let(:correspondence_2) { create(:correspondence, :with_single_doc, veteran_id: veteran.id, package_document_type_id: non_10182_package_type.id) }

    before do
      FeatureToggle.enable!(:correspondence_queue)
      mail_team_supervisor_org.add_user(mail_team_supervisor_user)
      User.authenticate!(user: mail_team_supervisor_user)
    end

    it "completes step 1 and 2 then goes to step 3 of intake appeal process" do
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
      click_button "Intake appeal"
      expect(page).to have_current_path("/intake/review_request")
      expect(page).to have_text `#{veteran.file_number}`
      expect(page).to have_text `Review #{veteran.first_name} #{veteran.last_name}'s Decision Review Request: Board Appeal (Notice of Disagreement) - VA Form 10182`
    end
  end

  context "Review package - Create record" do
    let(:non_10182_package_type) { PackageDocumentType.create(id: 1, active: true, name: "0304") }
    let(:correspondence_2) { create(:correspondence, :with_single_doc, veteran_id: veteran.id, package_document_type_id: non_10182_package_type.id) }

    before do
      FeatureToggle.enable!(:correspondence_queue)
      mail_team_org.add_user(mail_team_user)
      User.authenticate!(user: mail_team_user)
    end

    it "click on Create record button" do
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
      click_button "Create record"
      expect(page).to have_current_path("/queue/correspondence/#{correspondence.uuid}/intake")
      expect(page).to have_content("Add Related Correspondence")
      expect(page).to have_content("Add any related correspondence to the mail package that is in progress.")
      expect(page).to have_content("Is this correspondence related to prior mail?")
      expect(page).to have_content("Associate with prior Mail")
      expect(page).to have_content("Yes")
      expect(page).to have_content("No")
    end
  end
end
# rubocop:enable Layout/LineLength
