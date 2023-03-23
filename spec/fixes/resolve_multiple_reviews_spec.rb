# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe "resolve_multiple_reviews[task]" do

  include_context "rake"

  # create a test ep
  def new_ep(veteran_file_number, status_type_code, last_action_date, claim_type_code)
    Generators::EndProduct.build(
      veteran_file_number: veteran_file_number,
      bgs_attrs: {
        claim_type_code: claim_type_code,
        last_action_date: last_action_date,
        status_type_code: status_type_code
      }
    )
  end

  # create a test review
  def new_review(review_type, veteran_file_number, establishment_error)
    create(review_type, veteran_file_number: veteran_file_number, establishment_error: establishment_error)
  end

  let(:error_text) { "#<Caseflow::Error::DuplicateEp: Caseflow::Error::DuplicateEp>" }
  let(:setups) { [] }

  before do
    setups.each do |setup|
      create(:veteran, file_number: setup[:file_number])
      new_review(setup[:review_type], setup[:file_number], setup[:error_text])
      new_ep(setup[:file_number], setup[:status_type_code], setup[:last_action_date], setup[:claim_type_code])
    end
  end

  context "There are old reviews with DuplicateEP errors" do
    let(:setups) do
      [
        {
          file_number: "000_000_001",
          review_type: :higher_level_review,
          status_type_code: "CAN",
          last_action_date: 3.days.ago.mdY,
          claim_type_code: "030BLAH",
          error_text: error_text
        },
        {
          file_number: "000_000_002",
          review_type: :higher_level_review,
          status_type_code: "CLR",
          last_action_date: 2.days.ago.mdY,
          claim_type_code: "030BLAH",
          error_text: error_text
        },
        {
          file_number: "000_000_003",
          review_type: :supplemental_claim,
          status_type_code: "PEND",
          last_action_date: 2.days.ago.mdY,
          claim_type_code: "040BLAH",
          error_text: error_text
        },
        {
          file_number: "000_000_004",
          review_type: :supplemental_claim,
          status_type_code: "CLR",
          last_action_date: Time.zone.today.mdY,
          claim_type_code: "040BLAH",
          error_text: error_text
        }
      ]
    end

    it "resolves the duplicate EPs for the given type of reviews" do
      # Invoke the resolve_multiple_reviews task for HLRS
      run(rake resolve_multiple_reviews[hlr])

      # Expect both problem_hlrs to have been resolved
      expect(hlr.reload.establishment_error).to be_nil

      # Expect the output to include lines indicating that the EPs were established/cleared
      expect(output).to include("cleared")
    end
  end
end
