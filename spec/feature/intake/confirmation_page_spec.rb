# frozen_string_literal: true

feature "Intake Confirmation Page", :postgres do
  include IntakeHelpers

  before { setup_intake_flags }

  let!(:current_user) { User.authenticate!(roles: ["Mail Intake"]) }
  let(:before_ama_date) { 3.years.ago }

  describe "when completing a claim review" do
    describe "Confirmation copy" do
      context "When no end product is created" do
        let(:claim_review_type) { :higher_level_review }

        it "does not show tracked item if there is no End Product" do
          start_claim_review(claim_review_type)
          visit "/intake"
          click_intake_continue
          click_intake_add_issue

          # Add only one ineligible issue, so there will be no eligible issues, and no end product
          add_intake_nonrating_issue(date: before_ama_date.strftime("%m/%d/%Y"))
          add_untimely_exemption_response("No")
          click_intake_finish

          expect(page).to have_content("Intake completed")
          expect(page).to have_content("If needed, you may correct the issues")
          expect(page).to_not have_content("Informal Conference Tracked Item")
          expect(page).to have_content("Edit the notice letter to reflect the status of requested issues")
        end
      end

      [:higher_level_review, :supplemental_claim].each do |claim_review_type|
        describe "given a #{claim_review_type}" do
          it "shows EP related content if there is an end product created" do
            start_claim_review(claim_review_type)

            visit "/intake"
            click_intake_continue
            click_intake_add_issue
            # Add an eligible issue
            add_intake_nonrating_issue(date: 6.months.ago.mdY)
            click_intake_finish
            expect(page).to have_content("Intake completed")
            expect(page).to have_content("Nonrating EP is being established")
            expect(page).to have_content("If needed, you may correct the issues")
            expect(page).to have_content("Tracked Item") if claim_review_type == :higher_level_review
            expect(page).to have_content("Edit the notice letter to reflect the status of requested issues")
          end

          it "redirects you back if you manually visit /completed" do
            start_claim_review(claim_review_type)

            visit "/intake/completed"

            expect(page).to have_current_path("/intake/add_issues")
          end
        end
      end
    end
  end

  describe "when completing an appeal" do
    context "appeal has VHA issues" do
      let(:claim_review_type) { :board_appeal }
      it "displays the correct copy on confirmation page" do
        start_claim_review(claim_review_type)
        visit "/intake"
        click_intake_continue
        click_intake_add_issue

        add_intake_vha_issue(date: 2.days.ago)
        click_intake_finish

        expect(page).to_not have_content("Intake completed")
        expect(page).to have_content("Appeal recorded in pre-docket queue")
        expect(page).to have_content("If needed, you may correct the issues")
        expect(page).to_not have_content("Edit the notice letter to reflect the status of requested issues.")
        expect(page).to have_content("Appeal created and sent to VHA for document assessment.")
      end
    end
  end
end
