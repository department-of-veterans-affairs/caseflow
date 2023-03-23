require 'rails_helper'

RSpec.describe 'reviews:resolve_multiple_reviews' do
  let(:user) do
    OpenStruct.new(
      ip_address: '127.0.0.1',
      station_id: '283',
      css_id: 'CSFLOW',
      regional_office: 'DSUSER'
    )
  end

  #Not sure if I'm suppose to do both here for the subject
  subject do
    Rake::Task['reviews:resolve_multiple_reviews'].invoke('hlr')
    Rake::Task['reviews:resolve_multiple_reviews'].invoke('sc')
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


    describe "when type is hlr with duplicateEP error it is remediated" do
      # Run the Rake task with the HLR type argument
      Rake::Task['reviews:resolve_multiple_reviews'].invoke('hlr')

      it "Remediates hlr to be empty" do
        expect(hlrs).to be_empty
      end
    end
  end
end
