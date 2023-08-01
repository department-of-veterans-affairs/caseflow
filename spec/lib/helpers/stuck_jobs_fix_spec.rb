# frozen_string_literal: true

require "./lib/helpers/stuck_jobs_fix"

describe WarRoom::StuckJobsFix, :postgres do
  subject { WarRoom::StuckJobFix.new }

  let(:dta_error) { "DTA SC creation failed" }
  let(:claim_not_established_error) { "Claim not established." }
  let(:claim_date_dt_error) { "ClaimDateDt" }
  let(:sc_dta_for_appeal_error) { "Can't create a SC DTA for appeal" }
  let!(:veteran_file_number) { "111223333" }
  let!(:veteran) { create(:veteran, file_number: veteran_file_number) }
  let(:appeal) { create(:appeal, veteran_file_number: veteran_file_number) }

  let!(:hlr) { create(:higher_level_review, veteran_file_number: veteran_file_number, establishment_error: dta_error) }
  let!(:sc) { create(:supplemental_claim, veteran_file_number: veteran_file_number, decision_review_remanded: hlr) }
  let!(:decision_doc_with_error) do
    create(
      :decision_document,
      error: claim_date_dt_error,
      processed_at: 7.days.ago,
      uploaded_to_vbms_at: 7.days.ago,
      appeal: appeal
    )
  end

  let!(:epe) do
    create(
      :end_product_establishment,
      code: "030BGRNR",
      source: decision_doc_with_error,
      veteran_file_number: veteran_file_number,
      established_at: Time.zone.now
    )
  end

  before do
    Timecop.freeze(Time.zone.now)
    allow(subject).to receive(:upload_logs_to_s3).with(anything).and_return("logs")
  end

  let(:expected_logs) do
    "\n#{Time.zone.now} ClaimDateInvalidRemediationJob::Log - Found 1 Decision Document(s) with errors"
  end

  context "#claim_date_dt_fix" do
    subject { described_class.new("decision_document", "ClaimDateDt") }

    let!(:expected_logs) do
      " #{Time.zone.now} ClaimDateDt::Log - Summary Report. Total number of Records with Errors: 0"
    end

    before do
      create_list(:decision_document, 5)
      create_list(:decision_document, 2, error: claim_date_dt_error, processed_at: 7.days.ago,
                                         uploaded_to_vbms_at: 7.days.ago)
    end

    context "when error, processed_at and uploaded_to_vbms_at are populated" do
      it "clears the error field" do
        expect(subject.records_with_errors.count).to eq(3)
        subject.claim_date_dt_fix

        expect(subject.logs.last).to include(expected_logs)
        expect(decision_doc_with_error.reload.error).to be_nil
        expect(subject.records_with_errors.count).to eq(0)
      end
    end

    context "when either uploaded_to_vbms_at or processed_at are nil" do
      describe "when upladed_to_vbms_at is nil" do
        it "does not clear the error field" do
          decision_doc_with_error.update(uploaded_to_vbms_at: nil)

          expect(decision_doc_with_error.error).to eq("ClaimDateDt")

          subject.claim_date_dt_fix

          expect(decision_doc_with_error.reload.error).not_to be_nil
        end
      end

      describe "when processed_at is nil" do
        it "does not clear the error field" do
          decision_doc_with_error.update(processed_at: nil)
          expect(decision_doc_with_error.error).to eq("ClaimDateDt")

          subject.claim_date_dt_fix

          expect(decision_doc_with_error.reload.error).not_to be_nil
        end
      end
    end
  end

  context "#claim_not_established" do
    subject { described_class.new("decision_document", claim_not_established_error) }

    context "when code and established_at are present on epe" do
      it "clears the error field when epe code  is 030" do
        decision_doc_with_error.update(error: claim_not_established_error)
        epe.update(code: "030")
        subject.claim_not_established_fix

        expect(decision_doc_with_error.reload.error).to be_nil
      end

      it "clears the error field when epe code  is 040" do
        decision_doc_with_error.update(error: claim_not_established_error)
        epe.update(code: "040")
        subject.claim_not_established_fix

        expect(decision_doc_with_error.reload.error).to be_nil
      end

      it "clears the error field when epe code  is 930" do
        decision_doc_with_error.update(error: claim_not_established_error)
        epe.update(code: "930")
        subject.claim_not_established_fix

        expect(decision_doc_with_error.reload.error).to be_nil
      end

      it "clears the error field when epe code  is 682" do
        decision_doc_with_error.update(error: claim_not_established_error)
        epe.update(code: "682")
        subject.claim_not_established_fix

        expect(decision_doc_with_error.reload.error).to be_nil
      end
    end

    context "When either code or established_at are missing on epe" do
      describe "when code and established_at are nil" do
        it "does not clear error on decision_document" do
          decision_doc_with_error.update(error: claim_not_established_error)
          epe.update(code: nil)
          epe.update(established_at: nil)
          subject.claim_not_established_fix

          expect(decision_doc_with_error.reload.error).to eq(claim_not_established_error)
        end
      end
      describe "when code is nil" do
        it "does not clear error on decision_document" do
          decision_doc_with_error.update(error: claim_not_established_error)
          epe.update(code: nil)
          subject.claim_not_established_fix

          expect(decision_doc_with_error.reload.error).to eq(claim_not_established_error)
        end
      end

      describe "when established_at is nil" do
        it "does not clear error on decision_document" do
          decision_doc_with_error.update(error: claim_not_established_error)
          epe.update(established_at: nil)
          subject.claim_not_established_fix

          expect(decision_doc_with_error.reload.error).to eq(claim_not_established_error)
        end
      end
    end
  end

  context "#dta_sc_creation_failed_fix" do
    subject { described_class.new("higher_level_review", dta_error) }

    context "When SC has decision_review_remanded_id and decision_review_remanded_type" do
      it "clears the error field on related HLR" do
        subject.dta_sc_creation_failed_fix
        expect(hlr.reload.establishment_error).to be_nil
      end
    end

    context "When SC has decision_review_remanded_id and decision_review_remanded_type are nil" do
      describe "when decision_review_remanded_id is nil" do
        it "does not clear error field on related HLR" do
          sc.update(decision_review_remanded_id: nil)
          subject.dta_sc_creation_failed_fix
          expect(hlr.reload.establishment_error).to eql(dta_error)
        end
      end

      describe "when decision_review_remanded_type is nil" do
        it "does not clear error field on related HLR" do
          sc.update(decision_review_remanded_type: nil)
          subject.dta_sc_creation_failed_fix
          expect(hlr.reload.establishment_error).to eql(dta_error)
        end
      end
    end
  end

  context "#sc_dta_for_appeal_fix" do
    before do
      decision_doc_with_error.update(error: sc_dta_for_appeal_error)
    end

    subject { described_class.new("decision_document", sc_dta_for_appeal_error) }

    context "when payee_code is nil" do
      before do
        decision_doc_with_error.appeal.claimant.update(payee_code: nil)
      end
      # we need to manipulate the claimant.type for these describes
      describe "claimant.type is VeteranClaimant" do
        it "updates payee_code to 00" do
          subject.sc_dta_for_appeal_fix
          expect(decision_doc_with_error.appeal.claimant.payee_code).to eq("00")
        end

        it "clears error column" do
          subject.sc_dta_for_appeal_fix
          expect(decision_doc_with_error.reload.error).to be_nil
        end
      end

      describe "claimant.type is DependentClaimant" do
        it "updates payee_code to 10" do
          decision_doc_with_error.appeal.claimant.update(type: "DependentClaimant")
          subject.sc_dta_for_appeal_fix
          expect(decision_doc_with_error.appeal.claimant.payee_code).to eq("10")
        end

        it "clears error column" do
          decision_doc_with_error.appeal.claimant.update(type: "DependentClaimant")
          subject.sc_dta_for_appeal_fix
          expect(decision_doc_with_error.reload.error).to be_nil
        end
      end
    end

    context "when payee_code is populated" do
      it "does not update payee_code" do
        expect(decision_doc_with_error.appeal.claimant.payee_code).to eq("00")
        subject.sc_dta_for_appeal_fix
        expect(decision_doc_with_error.appeal.claimant.payee_code).to eq("00")
      end
      it "does not clear error field" do
        subject.sc_dta_for_appeal_fix
        expect(decision_doc_with_error.error).to eq(sc_dta_for_appeal_error)
      end
    end
  end
end
