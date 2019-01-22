require "support/intake_helpers"
require "byebug"

feature "Intake Edit Confirmation" do
  include IntakeHelpers

  before { setup_intake_flags }
  after { teardown_intake_flags }

  let!(:current_user) { User.authenticate!(roles: ["Mail Intake"]) }
  let!(:intake) { create(:intake, :completed, detail: decision_review, user_id: current_user.id) }

  describe "when editing a decision review" do
    let(:rating) do
      Generators::Rating.build(
        participant_id: decision_review.veteran.participant_id,
        profile_date: decision_review.receipt_date - 1.month,
        issues: [{ decision_text: "Left knee granted" }, { reference_id: "def456", decision_text: "PTSD denied" }]
      )
    end

    let(:request_issue) do
      create(:request_issue,
             rating_issue_reference_id: "def456",
             rating_issue_profile_date: rating.profile_date,
             review_request: decision_review,
             description: "PTSD denied")
    end

    before do
      decision_review.create_issues!([request_issue])
      decision_review.establish!
    end

    describe "given common behavior for claim reviews" do
      [:higher_level_review, :supplemental_claim].each do |claim_review_type|
        describe "given a #{claim_review_type}" do
          let(:decision_review) { create(claim_review_type, veteran_file_number: create(:veteran).file_number) }
          let(:edit_path) { "#{claim_review_type.to_s.pluralize}/#{get_claim_id(decision_review)}/edit" }

          it "confirms that an EP is being established" do
            visit edit_path
            click_intake_add_issue
            click_intake_no_matching_issues
            add_intake_nonrating_issue(date: (decision_review.receipt_date - 1.month).strftime("%D"))
            click_edit_submit
            click_number_of_issues_changed_confirmation

            expect(page).to have_current_path("/#{edit_path}/confirmation")
            expect(page).to have_content("A #{decision_review.class.review_title} Nonrating EP is being established")
          end

          it "shows when an EP is being canceled" do
            visit edit_path
            # first add a nonrating issue so we can remove the rating issue & EP
            click_intake_add_issue
            click_intake_no_matching_issues
            add_intake_nonrating_issue(date: (decision_review.receipt_date - 1.month).strftime("%D"))
            click_remove_intake_issue(1)
            click_remove_issue_confirmation
            click_edit_submit

            expect(page).to have_current_path("/#{edit_path}/confirmation")
            expect(page).to have_content("A #{decision_review.class.review_title} Rating EP is being canceled")
          end

          it "shows when an EP is being updated" do
            visit edit_path
            click_intake_add_issue
            add_intake_rating_issue("Left knee granted")
            click_edit_submit
            click_number_of_issues_changed_confirmation

            expect(page).to have_current_path("/#{edit_path}/confirmation")
            expect(page).to have_content(
              "Contentions on #{decision_review.class.review_title} Rating EP are being updated"
            )
          end

          it "includes warnings about unidentified issues" do
            visit edit_path
            click_intake_add_issue
            add_intake_unidentified_issue
            click_edit_submit
            click_still_have_unidentified_issue_confirmation
            click_number_of_issues_changed_confirmation

            expect(page).to have_current_path("/#{edit_path}/confirmation")
            expect(page).to have_content("There is still an unidentified issue")
          end

          it "does not say edit in VBMS if there are no end products" do
            visit edit_path
            click_intake_add_issue
            click_intake_no_matching_issues
            add_intake_nonrating_issue(date: (decision_review.receipt_date - 2.years).strftime("%D"))
            add_untimely_exemption_response("Yes") if claim_review_type == :higher_level_review
            click_remove_intake_issue(1)
            click_remove_issue_confirmation
            click_edit_submit

            expect(page).to have_current_path("/#{edit_path}/confirmation")
            expect(page).to have_content("A #{decision_review.class.review_title} Rating EP is being canceled")
            expect(page).to_not have_content("If you need to edit this, go to VBMS claim details")
          end
        end
      end
    end

    describe "given behavior specific to Higher-Level Reviews" do
      let(:decision_review) { create(:higher_level_review, veteran_file_number: create(:veteran).file_number) }
      let(:edit_path) { "higher_level_reviews/#{get_claim_id(decision_review)}/edit" }

      it "shows if an informal conference was requested" do
        decision_review.update!(informal_conference: true)

        visit edit_path
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")
        click_edit_submit
        click_number_of_issues_changed_confirmation

        expect(page).to have_current_path("/#{edit_path}/confirmation")
        expect(page).to have_content("Informal Conference Tracked Item")
      end

      it "does not show informal conference request if there are no end products" do
        decision_review.update!(informal_conference: true)

        visit edit_path
        click_intake_add_issue
        click_intake_no_matching_issues
        add_intake_nonrating_issue(date: (decision_review.receipt_date - 2.years).strftime("%D"))
        add_untimely_exemption_response("Yes")
        click_remove_intake_issue(1)
        click_remove_issue_confirmation
        click_edit_submit

        expect(page).to have_current_path("/#{edit_path}/confirmation")
        expect(page).to_not have_content("Informal Conference Tracked Item")
      end
    end

    describe "given an Appeal" do
      let(:decision_review) { create(:appeal, veteran_file_number: create(:veteran).file_number) }
      let(:appeal_path) { "appeals/#{decision_review.external_id}" }

      it "redirects back to the appeal after edit" do
        visit "#{appeal_path}/edit"
        expect(page).to have_current_path("/#{appeal_path}/edit")
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")
        click_edit_submit
        click_number_of_issues_changed_confirmation

        expect(page).to have_current_path("/queue/#{appeal_path}")
      end
    end
  end
end
