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
           reference_id: cleared_end_product.claim_id)
  end

  let!(:request_issue) do
    create(
      :request_issue,
      decision_review: claim_review,
      contested_rating_issue_reference_id: "def456",
      contested_rating_issue_profile_date: (receipt_date - 2.days).to_datetime,
      contested_issue_description: "PTSD denied",
      decision_date: Time.zone.now - 2.days,
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

    fcontext "when correct claim reviews feature is enabled" do
      it "allows a user to navigate to the edit page" do
        visit_editable_page_and_correct_request_issues("higher_level_reviews")
      end

      it "selecting to correct issue launches modal to set correction type" do
        visit_editable_page_and_test_correction_modal("higher_level_reviews")
      end
    end    
  end

  feature "with cleared end product on supplemental claim" do
    let(:claim_review) do
      SupplementalClaim.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        benefit_type: benefit_type,
        veteran_is_not_claimant: false
      )
    end

    it "edits are prevented if correct claim reviews feature is not enabled" do
      visit_non_editable_page("supplemental_claims")
      expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
    end

    context "when correct claim reviews feature is enabled" do
      it "allows a user to navigate to the edit page" do
        visit_editable_page_and_correct_request_issues("supplemental_claims")
      end
    end
  end
end

def visit_non_editable_page(type)
  visit "/#{type}/#{cleared_end_product.claim_id}/edit/"
  expect(page).to have_current_path("/#{type}/#{cleared_end_product.claim_id}/edit/cleared_eps")
  expect(page).to have_content("Issues Not Editable")
end

def visit_editable_page_and_correct_request_issues(type)
  enable_features
  visit "#{type}/#{cleared_end_product.claim_id}/edit/"
  expect(page).to have_content("Edit Issues")
  expect(page).to have_content("Cleared, waiting for decision")
  click_correct_intake_issue_dropdown("PTSD denied")
  expect(page).to have_selector(".intake-correction-type")
  select_correction_type_from_modal('control')
  click_correction_type_modal_submit
  expect(page).to have_content("This issue will be added to a 930 EP for correction")
  click_edit_submit
  expect(page).to have_content("You are now creating a 930 EP in VBMS")
  click_button("Yes, establish")
  expect(page).to have_content("Claim Issues Saved")
  disable_features
end

def visit_editable_page_and_test_correction_modal(type)
  enable_features
  visit "#{type}/#{cleared_end_product.claim_id}/edit/"
  expect(page).to have_content("Edit Issues")
  expect(page).to have_content("Cleared, waiting for decision")
  click_correct_intake_issue_dropdown("PTSD denied")
  expect(page).to have_selector(".intake-correction-type")

  expect(page).to have_selector("#correctionType_control")
  expect(page).to have_selector("#correctionType_local_quality_error")
  expect(page).to have_selector("#correctionType_national_quality_error")

  select_correction_type_from_modal('local_quality_error')
  click_correction_type_modal_submit
  expect(page).to have_content("This issue will be added to a 930 EP for correction")
  click_edit_submit
  expect(page).to have_content("You are now creating a 930 EP in VBMS")
  click_button("Yes, establish")
  expect(page).to have_content("Claim Issues Saved")
  disable_features
end

def enable_features
  FeatureToggle.enable!(:correct_claim_reviews)
  FeatureToggle.enable!(:withdraw_decision_review)
end

def disable_features
  FeatureToggle.disable!(:correct_claim_reviews)
  FeatureToggle.disable!(:withdraw_decision_review)
end
