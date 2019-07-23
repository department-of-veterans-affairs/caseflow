# frozen_string_literal: true

require "rails_helper"
require "support/intake_helpers"

feature "End Product Correction (EP 930)" do
  include IntakeHelpers

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:veteran) do
    create(:veteran,
           first_name: "Ed",
           last_name: "Merica")
  end

  let(:benefit_type) { "compensation" }
  let(:receipt_date) { Time.zone.today - 20 }
  let(:promulgation_date) { receipt_date - 2.days }
  let(:profile_date) { promulgation_date.to_datetime }
  let(:ep_code) { "030HLRR" }

  let(:cleared_end_product) do
    Generators::EndProduct.build(
      veteran_file_number: veteran.file_number,
      bgs_attrs: { status_type_code: "CLR" }
    )
  end

  let(:cleared_end_product_establishment) do
    create(:end_product_establishment,
           source: claim_review,
           synced_status: "CLR",
           code: ep_code,
           reference_id: cleared_end_product.claim_id)
  end

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" },
        { reference_id: "abcdef", decision_text: "Back pain" }
      ]
    )
  end

  let!(:cleared_request_issue) do
    create(
      :request_issue,
      decision_review: claim_review,
      contested_rating_issue_reference_id: "def456",
      decision_date: promulgation_date,
      contested_rating_issue_profile_date: profile_date,
      contested_issue_description: "PTSD denied",
      end_product_establishment: cleared_end_product_establishment
    )
  end

  feature "with cleared end product on higher level review" do
    let(:claim_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false,
        benefit_type: benefit_type,
        veteran_is_not_claimant: false
      )
    end

    it "edits are prevented if correct claim reviews feature is not enabled" do
      visit_non_editable_page("higher_level_reviews")
      expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
    end

    context "when correct claim reviews feature is enabled" do
      before { enable_features }
      after { disable_features }

      context "when a user corrects an existing issue" do
        it "creates a correction issue and EP, and closes the existing issue with no decision" do
          visit_edit_page("higher_level_reviews")
          correct_existing_request_issue
          submit_edit
        end
      end

      context "when a user adds a rating issue" do
        it "creates a correction issue and EP" do
          visit_edit_page("higher_level_reviews")
          click_intake_add_issue
          add_intake_rating_issue("Left knee granted")
          click_edit_submit
          safe_click ".confirm"
          confirm_930_modal
        end
      end

      context "when a user adds a nonrating issue" do
        it "creates a correction issue and EP" do

        end
      end

      context "when a user adds an unidentified issue" do
        it "creates a correction issue and EP" do

        end
      end

      it "allows a user to navigate to the edit page" do
        visit_editable_page_and_correct_request_issues("higher_level_reviews")
      end
    end
  end

  # feature "with cleared end product on supplemental claim" do
  #   let(:claim_review) do
  #     SupplementalClaim.create!(
  #       veteran_file_number: veteran.file_number,
  #       receipt_date: receipt_date,
  #       benefit_type: benefit_type,
  #       veteran_is_not_claimant: false
  #     )
  #   end
  #
  #   it "edits are prevented if correct claim reviews feature is not enabled" do
  #     visit_non_editable_page("supplemental_claims")
  #     expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
  #   end
  #
  #   context "when correct claim reviews feature is enabled" do
  #     it "allows a user to navigate to the edit page" do
  #       visit_edit_page("supplemental_claims")
  #       correct_existing_request_issue
  #       click_edit_submit
  #     end
  #   end
  # end
end

def visit_non_editable_page(type)
  visit "/#{type}/#{cleared_end_product.claim_id}/edit/"
  expect(page).to have_current_path("/#{type}/#{cleared_end_product.claim_id}/edit/cleared_eps")
  expect(page).to have_content("Issues Not Editable")
end

def correct_existing_request_issue
  click_correct_intake_issue_dropdown("PTSD denied")
  expect(page).to have_content("This issue will be added to a 930 EP for correction")
end

def visit_edit_page(type)
  visit "#{type}/#{cleared_end_product.claim_id}/edit/"
  expect(page).to have_content("Edit Issues")
  expect(page).to have_content("Cleared, waiting for decision")
end

def confirm_930_modal
  expect(page).to have_content("You are now creating a 930 EP in VBMS")
  click_button("Yes, establish")
  expect(page).to have_content("Claim Issues Saved")
end

def enable_features
  FeatureToggle.enable!(:correct_claim_reviews)
  FeatureToggle.enable!(:withdraw_decision_review)
end

def disable_features
  FeatureToggle.disable!(:correct_claim_reviews)
  FeatureToggle.disable!(:withdraw_decision_review)
end
