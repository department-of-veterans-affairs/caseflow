# frozen_string_literal: true

# rubocop:disable Layout/LineLength
RSpec.feature("The Correspondence Review Package page") do
  let(:veteran) { create(:veteran) }
  let(:correspondence) { create(:correspondence, :with_single_doc, veteran_id: veteran.id) }
  let(:mail_team_supervisor_user) { create(:inbound_ops_team_supervisor) }
  let(:mail_team_supervisor_org) { InboundOpsTeam.singleton }
  let(:inbound_ops_team_user) { create(:user) }
  let(:mail_team_org) { InboundOpsTeam.singleton }

  context "Review package feature toggle" do
    before :each do
      mail_team_supervisor_org.add_user(mail_team_supervisor_user)
      User.authenticate!(user: mail_team_supervisor_user)
      @correspondence_uuid = "123456789"
    end

    it "routes user to /under_construction if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
      expect(page).to have_current_path("/under_construction")
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
      expect(page).to have_button("Return to queue")
      expect(page).to have_button("Create record")
    end

    context "when remove package task is pending review" do
      before do
        parent_task = ReviewPackageTask.find_by(appeal_id: correspondence.id)
        RemovePackageTask.create!(
          parent_id: parent_task&.id,
          appeal_id: correspondence&.id,
          appeal_type: Correspondence.name,
          assigned_to: InboundOpsTeam.singleton
        )
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
        click_button("Confirm")
        using_wait_time(20) do
          expect(page).to have_content("The package has been removed from Caseflow and must be manually uploaded again from the Centralized Mail Portal, if it needs to be processed.")
        end
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
      end
    end
  end

  context "Review package - intake appeal" do
    let(:correspondence_2) { create(:correspondence, :nod, :with_single_doc, veteran_id: veteran.id) }

    before do
      FeatureToggle.enable!(:correspondence_queue)
      mail_team_supervisor_org.add_user(inbound_ops_team_user)
      MailTeam.singleton.add_user(inbound_ops_team_user)
      inbound_ops_team_user.update!(roles: ["Mail Intake"])
      User.authenticate!(user: inbound_ops_team_user)
    end

    it "completes step 1 and 2 then goes to step 3 of intake appeal process" do
      visit "/queue/correspondence/#{correspondence_2.uuid}/review_package"
      expect(page).to have_button("Intake appeal")
      click_button "Intake appeal"
      using_wait_time(20) do
        expect(page).to have_text veteran.file_number.to_s
        expect(page).to have_text "Review #{veteran.first_name} #{veteran.last_name}'s Decision Review Request: Board Appeal (Notice of Disagreement) — VA Form 10182"
      end
    end
  end

  context "Review package - Create record" do
    let(:correspondence_2) { create(:correspondence, :with_single_doc, veteran_id: veteran.id) }

    before do
      FeatureToggle.enable!(:correspondence_queue)
      mail_team_supervisor_org.add_user(mail_team_supervisor_user)
      User.authenticate!(user: mail_team_supervisor_user)
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

  context "Review package - check on ReviewPackageTask status" do
    let(:correspondence) { create(:correspondence, :with_single_doc, veteran_id: veteran.id) }

    before do
      FeatureToggle.enable!(:correspondence_queue)
      mail_team_supervisor_org.add_user(mail_team_supervisor_user)
      User.authenticate!(user: mail_team_supervisor_user)
      visit "/queue/correspondence/#{correspondence.uuid}/review_package"
    end

    it "before editing the review package general details" do
      expect(correspondence.tasks.find_by_type("ReviewPackageTask").status).to eq("unassigned")
    end

    it "after editing the review package general details" do
      fill_in "Notes", with: " Updated"
      expect(page).to have_button("Save changes", disabled: false)
      click_button "Save changes"
      refresh
      expect(correspondence.tasks.find_by_type("ReviewPackageTask").status).to eq("in_progress")
    end
  end
end
# rubocop:enable Layout/LineLength
