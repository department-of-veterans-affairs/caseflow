# frozen_string_literal: true

feature "Intake Edit EP Claim Labels", :all_dbs do
  include IntakeHelpers

  before do
    setup_intake_flags
    FeatureToggle.enable!(:edit_ep_claim_labels)
  end

  after do
    FeatureToggle.disable!(:edit_ep_claim_labels)
  end

  let!(:current_user) { User.authenticate!(roles: ["Mail Intake"]) }
  let(:veteran_file_number) { "123412345" }
  let(:veteran) { create(:veteran) }
  let(:receipt_date) { Time.zone.today - 20 }
  let(:profile_date) { 10.days.ago }
  let(:promulgation_date) { 9.days.ago.to_date }
  let!(:rating) { generate_rating_with_defined_contention(veteran, promulgation_date, profile_date) }
  let(:benefit_type) { "compensation" }

  let!(:higher_level_review) do
    create(
      :higher_level_review,
      veteran_file_number: veteran.file_number,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      legacy_opt_in_approved: false
    )
  end

  # create associated intake
  let!(:intake) do
    create(
      :intake,
      user: current_user,
      detail: higher_level_review,
      veteran_file_number: veteran.file_number,
      started_at: Time.zone.now,
      completed_at: Time.zone.now,
      completion_status: "success",
      type: "HigherLevelReviewIntake"
    )
  end

  let(:rating_request_issue) do
    create(
      :request_issue,
      contested_rating_issue_reference_id: "def456",
      contested_rating_issue_profile_date: rating.profile_date,
      decision_review: higher_level_review,
      benefit_type: benefit_type,
      contested_issue_description: "PTSD denied"
    )
  end

  let(:nonrating_request_issue) do
    create(
      :request_issue,
      :nonrating,
      decision_review: higher_level_review,
      benefit_type: benefit_type,
      contested_issue_description: "Apportionment"
    )
  end

  let(:ineligible_request_issue) do
    create(
      :request_issue,
      :nonrating,
      :ineligible,
      decision_review: higher_level_review,
      benefit_type: benefit_type,
      contested_issue_description: "Ineligible issue"
    )
  end

  let(:withdrawn_request_issue) do
    create(
      :request_issue,
      :nonrating,
      :withdrawn,
      decision_review: higher_level_review,
      contested_issue_description: "Issue that's been withdrawn"
    )
  end

  context "When editing a decision review with end products" do
    let(:new_ep_code) { "030HLRR" }

    before do
      higher_level_review.create_issues!(
        [
          rating_request_issue,
          nonrating_request_issue,
          ineligible_request_issue,
          withdrawn_request_issue
        ]
      )
      higher_level_review.establish!
    end

    context "When an update is made to an issue" do
      it "enables the Save btn and disables the Edit claim label btn, when you remove an issue" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

        nr_label = Constants::EP_CLAIM_TYPES[nonrating_request_issue.end_product_establishment.code]["official_label"]
        nr_row = page.find("tr", text: nr_label, match: :prefer_exact)

        expect(page).to have_button("Save", disabled: true)
        expect(nr_row).to have_button("Edit claim label", disabled: false)

        # make issue update - remove issue
        within "#issue-2" do
          select('Remove issue', :from => 'issue-action-0')
        end
        click_on("Yes, remove issue")

        expect(page).to have_button("Save", disabled: false)
        expect(page).to have_button("Edit claim label", disabled: true)
      end

      it "enables the Save btn and disables the Edit claim label btn, when you edit issue description" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
        nr_label = Constants::EP_CLAIM_TYPES[nonrating_request_issue.end_product_establishment.code]["official_label"]
        nr_row = page.find("tr", text: nr_label, match: :prefer_exact)

        expect(page).to have_button("Save", disabled: true)
        expect(nr_row).to have_button("Edit claim label", disabled: false)

        # make issue update - add issue
        click_on("Add issue")
        find(".cf-select", text: "Select or enter").click
        find(".cf-select__option", text: "Unknown issue category").click
        fill_in "decision-date", with: "08192020"
        fill_in "Issue description", with: "this is a description"
        click_on("Add this issue")

        expect(page).to have_button("Save", disabled: false)
        expect(page).to have_button("Edit claim label", disabled: true)
      end
    end

    it "shows each established end product label" do
      visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

      # First shows issues on end products, in ascending order by EP code (nonrating before rating)
      # Note for these, there's a row for the EP label, and a subsequent row for the issues
      nr_label = Constants::EP_CLAIM_TYPES[nonrating_request_issue.end_product_establishment.code]["official_label"]
      nr_row = page.find("tr", text: nr_label, match: :prefer_exact)

      expect(nr_row).to have_button("Edit claim label")
      nr_next_row = nr_row.first(:xpath, "./following-sibling::tr")
      expect(nr_next_row).to have_content(/Requested issues\n1. #{nonrating_request_issue.description}/i)

      r_label = Constants::EP_CLAIM_TYPES[rating_request_issue.end_product_establishment.code]["official_label"]
      r_row = page.find("tr", text: r_label, match: :prefer_exact)
      expect(r_row).to have_button("Edit claim label")
      r_next_row = r_row.first(:xpath, "./following-sibling::tr")
      expect(r_next_row).to have_content(/Requested issues\n2. #{rating_request_issue.description}/i)

      # Shows issues not on end products (single row)
      row = find("#table-row-12")
      expect(row).to have_content(/Requested issues\n3. #{ineligible_request_issue.description}/i)

      # Shows withdrawn issues last (single row)
      row = find("#table-row-13")
      expect(row).to have_content(
        /Withdrawn issues\n4. #{withdrawn_request_issue.description}/i
      )

      # Edit nonrating label to rating
      nr_row.find("button", text: "Edit claim label").click
      expect(page).to have_content(COPY::EDIT_CLAIM_LABEL_MODAL_NOTE)
      click_on "Cancel"

      expect(page).to_not have_content(COPY::EDIT_CLAIM_LABEL_MODAL_NOTE)

      nr_row.find("button", text: "Edit claim label").click
      safe_click ".cf-select"
      fill_in "Select the correct EP claim label", with: new_ep_code
      find("#select-claim-label").send_keys :enter
      find("button", text: "Continue").click

      expect(page).to have_content(COPY::CONFIRM_CLAIM_LABEL_MODAL_TITLE)
      expect(page).to have_content("Previous label: #{nr_label}")
      expect(page).to have_content("New label: #{r_label}")

      find("button", text: "Confirm").click

      expect(page).to_not have_content(COPY::EDIT_CLAIM_LABEL_MODAL_NOTE)
      sleep 1 # when frontend displays result of XHR, write a capybara expect against that

      expect(EndProductUpdate.find_by(original_decision_review: higher_level_review)).to_not be_nil
      expect(higher_level_review.end_product_establishments.where(code: new_ep_code).count).to eq(2)
    end
  end
end
