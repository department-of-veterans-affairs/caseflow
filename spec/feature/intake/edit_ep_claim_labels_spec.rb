# frozen_string_literal: true

feature "Intake Edit EP Claim Labels", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(Time.zone.today)
    User.authenticate!(roles: ["Admin Intake"])
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
          select("Remove issue", from: "issue-action-0")
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

      expect(page).to have_current_path("/search?veteran_ids=#{higher_level_review.veteran.id}")
      expect(page).to have_content COPY::EDIT_EP_CLAIM_LABEL_SUCCESS_ALERT_TITLE
      expect(page).to have_content COPY::EDIT_EP_CLAIM_LABEL_SUCCESS_ALERT_MESSAGE

      expect(EndProductUpdate.find_by(original_decision_review: higher_level_review)).to_not be_nil
      expect(higher_level_review.end_product_establishments.where(code: new_ep_code).count).to eq(2)
    end

    context "when the end product correction feature toggle is enabled" do
      before { FeatureToggle.enable!(:correct_claim_reviews) }
      after { FeatureToggle.disable!(:correct_claim_reviews) }

      before do
        rating_ep = higher_level_review.end_product_establishments.find_by(code: "030HLRR")
        nonrating_ep = higher_level_review.end_product_establishments.find_by(code: "030HLRNR")

        # This creates EPs in the Fakes so that they are available for syncing
        Generators::EndProduct.build(
          veteran_file_number: rating_ep.veteran_file_number,
          bgs_attrs: {
            claim_type_code: rating_ep.code,
            end_product_type_code: rating_ep.modifier,
            benefit_claim_id: rating_ep.reference_id,
            last_action_date: 5.days.ago.to_formatted_s(:short_date),
            status_type_code: "CLR"
          }
        )

        Generators::EndProduct.build(
          veteran_file_number: nonrating_ep.veteran_file_number,
          bgs_attrs: {
            claim_type_code: nonrating_ep.code,
            end_product_type_code: nonrating_ep.modifier,
            benefit_claim_id: nonrating_ep.reference_id,
            last_action_date: 5.days.ago.to_formatted_s(:short_date),
            status_type_code: "CAN"
          }
        )
      end

      it "hides cancelled claims and disables edits on cleared claims" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

        # Cancelled EPs do not show on the UI
        nr_label = Constants::EP_CLAIM_TYPES[nonrating_request_issue.end_product_establishment.code]["official_label"]
        expect(page.has_no_content?(nr_label)).to eq(true)

        # Edit button on Cleared claim is disabled
        # Note: Cleared EPs only appear when the end product correction feature toggle is enabled
        r_label = Constants::EP_CLAIM_TYPES[rating_request_issue.end_product_establishment.code]["official_label"]
        r_row = page.find("tr", text: r_label, match: :prefer_exact)
        expect(r_row).to have_button("Edit claim label", disabled: true)
      end
    end

    context "show edit ep error message" do
      let(:new_ep_code) { "030HLRRPMC" }
      let(:ep_code) { "030HLRNR" }
      let(:synced_status) { "PEND" }
      let(:payee_code) { "00" }
      let(:modifier) { "030" }

      let!(:end_product) do
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: {
            benefit_claim_id: "123456",
            claim_type_code: ep_code,
            end_product_type_code: modifier,
            payee_type_code: payee_code,
            status_type_code: synced_status
          }
        )
      end

      let(:reference_id) { end_product.claim_id }

      let(:end_product_establishment) do
        create(:end_product_establishment,
               :active,
               source: higher_level_review,
               synced_status: synced_status,
               code: ep_code,
               reference_id: reference_id,
               payee_code: payee_code,
               modifier: modifier)
      end

      let(:rating_request_issue) do
        create(
          :request_issue,
          contested_rating_issue_reference_id: "def456",
          contested_rating_issue_profile_date: rating.profile_date,
          decision_review: higher_level_review,
          benefit_type: benefit_type,
          contested_issue_description: "PTSD denied",
          end_product_establishment: end_product_establishment
        )
      end

      let(:nonrating_request_issue) do
        create(
          :request_issue,
          :nonrating,
          decision_review: higher_level_review,
          benefit_type: benefit_type,
          contested_issue_description: "Apportionment",
          end_product_establishment: end_product_establishment
        )
      end

      let!(:bgs) { BGSService.new }

      before do
        higher_level_review.create_issues!(
          [
            rating_request_issue,
            nonrating_request_issue
          ]
        )
        higher_level_review.establish!
        allow(BGSService).to receive(:new) { bgs }
        allow(bgs).to receive(:update_benefit_claim).and_raise(BGS::ShareError, "bgs error")
      end

      it "shows error message when claim is not correct" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
        nr_label = Constants::EP_CLAIM_TYPES[nonrating_request_issue.end_product_establishment.code]["official_label"]
        nr_row = page.find("tr", text: nr_label, match: :prefer_exact)
        nr_row.find("button", text: "Edit claim label").click
        safe_click ".cf-select"
        fill_in "Select the correct EP claim label", with: new_ep_code
        find("#select-claim-label").send_keys :enter
        find("button", text: "Continue").click

        expect(page).to have_content(COPY::CONFIRM_CLAIM_LABEL_MODAL_TITLE)

        find("button", text: "Confirm").click

        expect(page).to_not have_content(COPY::EDIT_CLAIM_LABEL_MODAL_NOTE)
        expect(page).to have_content("We were unable to edit the claim label.")

        epu = EndProductUpdate.find_by(error: "bgs error", status: "error")

        expect(epu).to_not be_nil
        expect(epu.end_product_establishment.reload.code).to eq(ep_code)
      end
    end

    context "shows edit claim" do
      let(:decision_review_remanded) { nil }

      let!(:supplemental_claim) do
        SupplementalClaim.create!(
          veteran_file_number: veteran.file_number,
          receipt_date: receipt_date,
          benefit_type: benefit_type,
          decision_review_remanded: decision_review_remanded,
          veteran_is_not_claimant: true
        )
      end

      # create intake
      let!(:intake) do
        Intake.create!(
          user_id: current_user.id,
          detail: supplemental_claim,
          veteran_file_number: veteran.file_number,
          started_at: Time.zone.now,
          completed_at: Time.zone.now,
          completion_status: "success",
          type: "SupplementalClaimIntake"
        )
      end

      let(:rating_ep_claim_id) do
        EndProductEstablishment.find_by(
          source: supplemental_claim,
          code: "040SCR"
        ).reference_id
      end

      let(:rating_request_issue) do
        create(
          :request_issue,
          contested_rating_issue_reference_id: "def456",
          contested_rating_issue_profile_date: rating.profile_date,
          decision_review: supplemental_claim,
          benefit_type: benefit_type,
          contested_issue_description: "PTSD denied"
        )
      end

      let(:nonrating_request_issue) do
        create(
          :request_issue,
          :nonrating,
          decision_review: supplemental_claim,
          benefit_type: benefit_type,
          contested_issue_description: "Apportionment"
        )
      end

      before do
        supplemental_claim.create_issues!(
          [
            rating_request_issue,
            nonrating_request_issue
          ]
        )
        supplemental_claim.establish!
      end
      let(:new_ep_code) { "040BDER" }

      it "handles error in when Ep is not updated" do
        allow_any_instance_of(ClaimReviewController).to receive(:perform_ep_update!).and_raise(StandardError)

        visit "supplemental_claims/#{rating_ep_claim_id}/edit"
        nr_label = Constants::EP_CLAIM_TYPES[nonrating_request_issue.end_product_establishment.code]["official_label"]
        nr_row = page.find("tr", text: nr_label, match: :prefer_exact)
        nr_row.find("button", text: "Edit claim label").click
        safe_click ".cf-select"

        fill_in "Select the correct EP claim label", with: new_ep_code
        find("#select-claim-label").send_keys :enter
        find("button", text: "Continue").click

        expect(page).to have_content(COPY::CONFIRM_CLAIM_LABEL_MODAL_TITLE)
        find("button", text: "Confirm").click

        expect(page).to have_content("We were unable to edit the claim label.")
        expect(page).to_not have_content(COPY::EDIT_CLAIM_LABEL_MODAL_NOTE)
        expect(page).to_not have_current_path("/search?veteran_ids=#{supplemental_claim.veteran.id}")
      end
    end
  end
end
