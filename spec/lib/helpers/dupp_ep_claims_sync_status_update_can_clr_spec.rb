# frozen_string_literal: true

require "helpers/dupp_ep_claims_sync_status_update_can_clr"

describe "DuppEpClaimsSyncStatusUpdateCanClr", :postgres do
  let(:script) { WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new }
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
    create(review_type, :with_end_product_establishment,
           veteran_file_number: veteran_file_number,
           establishment_error: establishment_error)
  end

  let(:error_text) { "#<Caseflow::Error::DuplicateEp: Caseflow::Error::DuplicateEp>" }

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
          file_number: "500_000_001",
          review_type: :higher_level_review,
          status_type_code: "CAN",
          last_action_date: 3.days.ago.mdY,
          claim_type_code: "030BLAH",
          error_text: error_text
        },
        {
          file_number: "500_000_002",
          review_type: :higher_level_review,
          status_type_code: "CLR",
          last_action_date: 2.days.ago.mdY,
          claim_type_code: "030BLAH",
          error_text: error_text
        },
        {
          file_number: "500_000_003",
          review_type: :supplemental_claim,
          status_type_code: "PEND",
          last_action_date: 2.days.ago.mdY,
          claim_type_code: "040BLAH",
          error_text: error_text
        },
        {
          file_number: "500_000_004",
          review_type: :supplemental_claim,
          status_type_code: "CLR",
          last_action_date: Time.zone.today.mdY,
          claim_type_code: "040BLAH",
          error_text: error_text
        }
      ]
    end

    describe "#retrieve_problem_reviews" do
      subject { script.retrieve_problem_reviews.count }

      it "pulls all the bad Reviews with CAN/CLR statuses that need manual remediation" do
        expect(subject).to eq 3
      end
    end

    describe "#resolve_duplicate_end_products" do
      let(:problem_reviews) { script.retrieve_problem_reviews }

      it "clears the problem_reviews list" do
        allow(script).to receive(:active_duplicates).and_return(true)
        allow(script).to receive(:upload_logs_to_s3_bucket).with(anything).and_return(true)
        script.resolve_duplicate_end_products(problem_reviews, problem_reviews.count)
        expect(script.retrieve_problem_reviews.count).to eq 0
      end
    end

    describe "#resolve_dup_ep" do
      let(:initial_pr_count) { script.retrieve_problem_reviews.count }
      it "performs the remediation successfully" do
        allow(script).to receive(:active_duplicates).and_return(true)
        allow(script).to receive(:upload_logs_to_s3_bucket).with(anything).and_return(true)

        expect(initial_pr_count).to eq 3
        script.resolve_dup_ep
        expect(script.retrieve_problem_reviews.count).to eq 0
      end
    end
  end

  context "There are only new reviews with DuplicateEP errors" do
    let(:setups) do
      [
        {
          file_number: "999_100_001",
          review_type: :higher_level_review,
          status_type_code: "CAN",
          last_action_date: Time.zone.today.mdY,
          claim_type_code: "030BLAH",
          error_text: error_text
        },
        {
          file_number: "999_100_002",
          review_type: :higher_level_review,
          status_type_code: "CLR",
          last_action_date: Time.zone.today.mdY,
          claim_type_code: "030BLAH",
          error_text: error_text
        }

      ]
    end

    describe "#resolve_dup_ep" do
      let(:initial_pr_count) { script.retrieve_problem_reviews.count }
      it "does not perform a remediation" do
        expect(initial_pr_count).to eq 0
        script.resolve_dup_ep
        expect(script.retrieve_problem_reviews.count).to eq 0
      end
    end
  end

  context "when no reviews with DuplicateEP errors" do
    let(:setups) do
      [
        {
          file_number: "000_500_001",
          review_type: :higher_level_review,
          status_type_code: "CAN",
          last_action_date: 13.days.ago.mdY,
          claim_type_code: "030BLAH",
          error_text: ""
        },
        {
          file_number: "000_500_002",
          review_type: :supplemental_claim,
          status_type_code: "CLR",
          last_action_date: 22.days.ago.mdY,
          claim_type_code: "040BLAH",
          error_text: ""
        }
      ]
    end

    describe "#resolve_dup_ep" do
      let(:initial_pr_count) { script.retrieve_problem_reviews.count }
      it "logs a message do does nothing" do
        expect(initial_pr_count).to eq 0
        expect(Rails.logger).to receive(:info).with("No records with errors found.").once
        script.resolve_dup_ep
      end
    end
  end

  context "#resolve_single_review" do
    context "Single HLR with DuplicateEP errors" do
      let(:setups) do
        [
          {
            file_number: "200_000_001",
            review_type: :higher_level_review,
            status_type_code: "CAN",
            last_action_date: 3.days.ago.mdY,
            claim_type_code: "030BLAH",
            error_text: error_text
          }
        ]
      end

      let(:initial_pr_count) { script.retrieve_problem_reviews.count }
      let(:problem_reviews) { script.retrieve_problem_reviews }
      it "resolves the HLR review only" do
        expect(initial_pr_count).to eq 1
        allow(script).to receive(:active_duplicates).and_return(true)
        allow(script).to receive(:upload_logs_to_s3_bucket).with(anything).and_return(true)

        script.resolve_single_review(problem_reviews.first.id, "hlr")
        expect(script.retrieve_problem_reviews.count).to eq 0
      end
    end

    context "Single SC with DuplicateEP errors" do
      let(:setups) do
        [
          {
            file_number: "100_000_001",
            review_type: :supplemental_claim,
            status_type_code: "CAN",
            last_action_date: 3.days.ago.mdY,
            claim_type_code: "030BLAH",
            error_text: error_text
          }
        ]
      end

      let(:initial_pr_count) { script.retrieve_problem_reviews.count }
      let(:problem_reviews) { script.retrieve_problem_reviews }
      it "resolves the SC review only" do
        expect(initial_pr_count).to eq 1
        allow(script).to receive(:active_duplicates).and_return(true)
        allow(script).to receive(:upload_logs_to_s3_bucket).with(anything).and_return(true)

        script.resolve_single_review(problem_reviews.first.id, "sc")
        expect(script.retrieve_problem_reviews.count).to eq 0
      end
    end
  end
end
