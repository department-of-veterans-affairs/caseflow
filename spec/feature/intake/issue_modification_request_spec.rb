# frozen_string_literal: true

feature "Issue Modification Request", :postgres do
  let(:veteran_file_number) { "123412345" }

  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number,
                              first_name: "Ed",
                              last_name: "Merica")
  end

  let!(:vha_org) { VhaBusinessLine.singleton }

  let!(:in_progress_task) do
    create(:higher_level_review,
           :with_vha_issue,
           :with_end_product_establishment,
           :processed,
           benefit_type: "vha",
           veteran: veteran,
           claimant_type: :veteran_claimant)
  end

  context "non-admin user" do
    let!(:current_user) do
      User.authenticate!(roles: ["System Admin", "Certify Appeal", "Mail Intake", "Admin Intake"])
    end

    before do
      vha_org.add_user(current_user)
    end

    it "should open the edit issues page and show non-admin content" do
      visit "higher_level_reviews/#{in_progress_task.uuid}/edit"

      expect(page).to have_content("Request additional issue")
    end

    it "does not enable the submit button until all fields are touched" do
      visit "higher_level_reviews/#{in_progress_task.uuid}/edit"

      step "for modification" do
        within "#issue-#{in_progress_task.request_issues.first.id}" do
          first("select").select("Request modification")
        end

        expect(page).to have_button("Submit request", disabled: true)

        fill_in "Issue type", with: "Beneficiary Travel"
        find(".cf-select__option", exact_text: "Beneficiary Travel").click

        fill_in "Prior decision date", with: "05/15/2024"
        fill_in "Issue description", with: "An issue description"
        fill_in "Please provide a reason for the issue modification request", with: "I wanted to"

        expect(page).to have_button("Submit request", disabled: false)

        within ".cf-modal-body" do
          click_on "Cancel"
        end
      end

      step "for addition" do
        click_on "Request additional issue"

        expect(page).to have_button("Submit request", disabled: true)

        fill_in "Issue type", with: "Beneficiary Travel"
        find(".cf-select__option", exact_text: "Beneficiary Travel").click

        fill_in "Prior decision date", with: "05/15/2024"
        fill_in "Issue description", with: "An issue description"
        fill_in "Please provide a reason for the issue addition request", with: "I wanted to"

        expect(page).to have_button("Submit request", disabled: false)

        within ".cf-modal-body" do
          click_on "Cancel"
        end
      end

      step "for withdrawal" do
        within "#issue-#{in_progress_task.request_issues.first.id}" do
          first("select").select("Request withdrawal")
        end

        expect(page).to have_button("Submit request", disabled: true)

        fill_in "Request date for withdrawal", with: "05/15/2024"
        fill_in "Please provide a reason for the issue withdrawal request", with: "I wanted to"

        expect(page).to have_button("Submit request", disabled: false)

        within ".cf-modal-body" do
          click_on "Cancel"
        end
      end

      step "for removal" do
        within "#issue-#{in_progress_task.request_issues.first.id}" do
          first("select").select("Request removal")
        end

        expect(page).to have_button("Submit request", disabled: true)

        fill_in "Please provide a reason for the issue removal request", with: "I wanted to"

        expect(page).to have_button("Submit request", disabled: false)

        within ".cf-modal-body" do
          click_on "Cancel"
        end
      end
    end

    it "moves issues to the pending admin review section when the issue modification modal is submitted" do
      visit "higher_level_reviews/#{in_progress_task.uuid}/edit"

      expect(page).not_to have_text("Pending admin review")

      within "#issue-#{in_progress_task.request_issues.first.id}" do
        first("select").select("Request modification")
      end

      fill_in "Issue type", with: "Beneficiary Travel"
      find(".cf-select__option", exact_text: "Beneficiary Travel").click

      fill_in "Prior decision date", with: "05/15/2024"
      fill_in "Issue description", with: "An issue description"
      fill_in "Please provide a reason for the issue modification request", with: "I wanted to"

      click_on "Submit request"

      pending_section = find("tr", text: "Pending admin review")

      expect(pending_section).to have_text("An issue description")
      expect(pending_section).to have_text("I wanted to")
      expect(pending_section).to have_text("05/15/2024")
      expect(pending_section).to have_text("Beneficiary Travel")

      ri = in_progress_task.request_issues.first
      expect(pending_section).to have_text("Original Issue")
      expect(pending_section).to have_text("#{ri.nonrating_issue_category} - #{ri.nonrating_issue_description}".strip)
      expect(pending_section).to have_text(Constants::BENEFIT_TYPES["vha"])
      expect(pending_section).to have_text(ri.decision_date.strftime("%m/%d/%Y").to_s)
    end
  end

  context "admin user" do
    let!(:current_user) do
      User.authenticate!(roles: ["System Admin", "Certify Appeal", "Mail Intake", "Admin Intake"])
    end

    before do
      vha_org.add_user(current_user)
      OrganizationsUser.make_user_admin(current_user, vha_org)
    end

    it "should open the edit issues page and not see the new non-admin content" do
      visit "higher_level_reviews/#{in_progress_task.uuid}/edit"

      expect(page.has_no_content?("Request additional issue")).to eq(true)
    end
  end
end
