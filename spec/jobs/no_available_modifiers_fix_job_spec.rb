# frozen_string_literal: true

describe NoAvailableModifiersFixJob, :postres do
  let(:error_text) { "EndProductModifierFinder::NoAvailableModifiers" }
  let(:file_number) { "123454321" }

  let!(:vet) do
    create(
      :veteran,
      file_number: file_number
    )
  end

  let!(:supplemental_claim_with_error) do
    create(
      :supplemental_claim,
      veteran_file_number: file_number,
      establishment_error: error_text
    )
  end
  let!(:supplemental_claim_with_error_2) do
    create(
      :supplemental_claim,
      veteran_file_number: file_number,
      establishment_error: error_text
    )
  end

  let!(:epe) do
    create(
      :end_product_establishment,
      veteran_file_number: file_number,
      source_type: "SupplementalClaim",
      source_id: supplemental_claim_with_error.id,
      modifier: nil
    )
  end

  before do
    create_list(:end_product_establishment, 5, veteran_file_number: file_number, modifier: nil,
                                               source_type: "SupplementalClaim")
    create_list(:end_product_establishment, 2, veteran_file_number: file_number, modifier: "030",
                                               source_type: "HigherLevelReview", synced_status: "CLR")

    create_list(:end_product_establishment, 5, veteran_file_number: file_number, modifier: "040",
                                               source_type: "SupplementalClaim", synced_status: "CAN")
  end

  subject { described_class.new }

  context "when there are fewer than 10 active end products" do
    describe "when there are 0 active end products" do
      it "runs decision_review_process_job on up to 10 Supplemental Claims" do
        subject.perform
        expect(DecisionReviewProcessJob).to have_been_enqueued.exactly(:twice)
      end
    end

    describe "when there are 9 active end products" do
      before do
        create_list(:end_product_establishment, 4, veteran_file_number: file_number, modifier: "040",
                                                   source_type: "SupplementalClaim", synced_status: "PEND")
        create_list(:end_product_establishment, 5, veteran_file_number: file_number, modifier: "040",
                                                   source_type: "SupplementalClaim", synced_status: "RW")
      end

      it "runs decision_review_process_job on 1 Supplemental Claim" do
        subject.perform
        expect(DecisionReviewProcessJob).to have_been_enqueued.exactly(:once).with(instance_of(SupplementalClaim))
      end
    end
    describe "when there are 5 active end products" do
      before do
        create_list(:end_product_establishment, 5, veteran_file_number: file_number, modifier: "040",
                                                   source_type: "SupplementalClaim", synced_status: "PEND")
        create_list(:supplemental_claim, 4, veteran_file_number: file_number,
                                            establishment_error: error_text)
      end

      it "runs decision_review_process_job on up to 5 Supplemental Claims" do
        subject.perform
        expect(DecisionReviewProcessJob).to have_been_enqueued.at_most(5).times.with(instance_of(SupplementalClaim))
      end
    end
  end

  context "when there are 10 active end products" do
    before do
      create_list(:end_product_establishment, 10, veteran_file_number: file_number, modifier: "040",
                                                  source_type: "SupplementalClaim", synced_status: "PEND")
    end

    it "does not run decision_review_process_job on any Supplemental Claims" do
      subject.perform
      expect(DecisionReviewProcessJob).not_to have_been_enqueued.with(instance_of(SupplementalClaim))
    end

    describe "when there are more than 10 active end products" do
      it "does not run decision_review_process_job on any Supplemental Claims" do
        epe.update(synced_status: "PEND")
        subject.perform
        expect(DecisionReviewProcessJob).not_to have_been_enqueued.with(instance_of(SupplementalClaim))
      end
    end
  end
end
