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

    it "shows errors when a user tries to submit missing information" do
      visit "higher_level_reviews/#{in_progress_task.uuid}/edit"

      step "for modification" do
        within "#issue-#{in_progress_task.request_issues.first.id}" do
          first("select").select("Request modification")
        end

        click_on "Submit request"

        expect(page).to have_content("Please select an issue type.")
        expect(page).to have_content("Please select a decision date.")
        expect(page).to have_content("Please enter an issue description.")
        expect(page).to have_content("Please enter a request reason.")

        click_on "Cancel"
      end

      step "for addition" do
        click_on "Request additional issue"
        click_on "Submit request"

        expect(page).to have_content("Please select an issue type.")
        expect(page).to have_content("Please select a decision date.")
        expect(page).to have_content("Please enter an issue description.")
        expect(page).to have_content("Please enter a request reason.")

        click_on "Cancel"
      end

      step "for withdrawal" do
        within "#issue-#{in_progress_task.request_issues.first.id}" do
          first("select").select("Request withdrawal")
        end

        click_on "Submit request"

        expect(page).to have_content("Please enter a withdrawal date.")
        expect(page).to have_content("Please enter a request reason.")

        click_on "Cancel"
      end

      step "for removal" do
        within "#issue-#{in_progress_task.request_issues.first.id}" do
          first("select").select("Request removal")
        end

        click_on "Submit request"

        expect(page).to have_content("Please enter a request reason.")

        click_on "Cancel"
      end
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

      expect(page).not_to have_content("Request additional issue")
    end
  end
end
