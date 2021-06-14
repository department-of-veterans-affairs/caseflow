# frozen_string_literal: true

describe DecisionDocument, :postgres do
  include IntakeHelpers

  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  let(:veteran) { create(:veteran) }
  let(:claimant_participant_id) { "2019111203" }
  let(:claimant) { create(:claimant, participant_id: claimant_participant_id) }
  let(:appeal) do
    create(:appeal, claimants: [claimant], veteran_file_number: veteran.file_number)
  end

  let(:decision_document) do
    create(:decision_document, file: file, processed_at: processed_at,
                               uploaded_to_vbms_at: uploaded_to_vbms_at, appeal: appeal)
  end

  let(:file) { nil }
  let(:uploaded_to_vbms_at) { nil }
  let(:processed_at) { nil }

  context "#pdf_location" do
    subject { decision_document.pdf_location }

    it "should fetch file from s3 and return temporary location" do
      expect(Caseflow::Fakes::S3Service).to receive(:fetch_file)
      expect(subject).to eq File.join(Rails.root, "tmp", "pdfs", decision_document.appeal.external_id + ".pdf")
    end
  end

  context "#submit_for_processing!" do
    subject { decision_document.submit_for_processing! }

    let(:expected_path) { "decisions/#{decision_document.appeal.external_id}.pdf" }
    let!(:decision_issue) { create(:decision_issue, decision_review: appeal, caseflow_decision_date: nil) }

    context "when there is a file" do
      let(:file) { "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW" }

      it "caches the file" do
        expect(S3Service).to receive(:store_file).with(expected_path, /PDF/)
        subject
        expect(decision_document.submitted_at).to eq(Time.zone.now)
      end

      it "updates the decision date on decision issues" do
        subject
        expect(decision_issue.reload.caseflow_decision_date).to_not be_nil
        expect(decision_issue.caseflow_decision_date).to eq(decision_document.decision_date)
      end
    end

    context "when no file" do
      it "raises NoFileError" do
        expect { subject }.to raise_error(DecisionDocument::NoFileError)
        expect(decision_document.submitted_at).to be_nil
      end
    end
  end

  context "#on_sync" do
    subject { decision_document.on_sync(end_product_establishment) }

    include ActiveJob::TestHelper

    after do
      clear_enqueued_jobs
    end

    let(:board_grant_effectuation) do
      BoardGrantEffectuation.create(
        granted_decision_issue: granted_decision_issue
      )
    end

    let(:end_product_establishment) { board_grant_effectuation.end_product_establishment }

    let!(:granted_decision_issue) do
      create(
        :decision_issue,
        :rating,
        disposition: "allowed",
        decision_review: decision_document.appeal
      )
    end

    context "when end product is not cleared" do
      before { end_product_establishment.update!(synced_status: "PEND") }
      it "does nothing" do
        subject
        expect(board_grant_effectuation).to_not be_attempted
      end
    end

    context "when end product is cleared" do
      before { end_product_establishment.update!(synced_status: "CLR") }
      it "submits the effectuation for processing and enqueues DecisionIssueSyncJob" do
        subject
        board_grant_effectuation.reload
        expect(board_grant_effectuation.decision_sync_submitted_at).to eq(Time.zone.now)
        expect(board_grant_effectuation.decision_sync_last_submitted_at).to eq(
          Time.zone.now + BoardGrantEffectuation.processing_retry_interval_hours.hours
        )

        # because we set delay, neither "submitted" nor queued.
        expect(board_grant_effectuation).to be_submitted
        expect(board_grant_effectuation).to_not be_submitted_and_ready
        expect(DecisionIssueSyncJob).to_not have_been_enqueued.with(board_grant_effectuation)
      end
    end
  end

  context "#process!" do
    subject { decision_document.process! }

    before do
      allow(decision_document).to receive(:submitted_and_ready?).and_return(true)
      allow(VBMSService).to receive(:upload_document_to_vbms).and_call_original
      allow(VBMSService).to receive(:establish_claim!).and_call_original
      allow(VBMSService).to receive(:create_contentions!).and_call_original
    end

    let!(:prior_sc_with_payee_code) { setup_prior_claim_with_payee_code(appeal, veteran) }

    context "the document has already been uploaded" do
      let(:uploaded_to_vbms_at) { Time.zone.now }

      it "does not reupload the document" do
        subject
        expect(VBMSService).to_not have_received(:upload_document_to_vbms)
      end
    end

    context "there was no upload error" do
      let!(:denied_issue) do
        create(
          :decision_issue,
          :rating,
          disposition: "denied",
          decision_review: decision_document.appeal
        )
      end

      context "when no granted or remanded issues" do
        it "uploads document and does not create effectuations" do
          subject

          expect(VBMSService).to have_received(:upload_document_to_vbms).with(
            decision_document.appeal, decision_document
          )

          expect(VBMSService).to_not have_received(:establish_claim!)
          expect(VBMSService).to_not have_received(:create_contentions!)
          expect(decision_document.effectuations).to be_empty

          expect(decision_document.attempted_at).to eq(Time.zone.now)
          expect(decision_document.processed_at).to eq(Time.zone.now)

          expect(SupplementalClaim.where(decision_review_remanded: decision_document.appeal)).to eq([])
        end
      end

      context "when remanded issues" do
        let!(:remanded_issue) do
          create(
            :decision_issue,
            decision_review: decision_document.appeal,
            disposition: "remanded",
            caseflow_decision_date: decision_document.decision_date
          )
        end

        it "creates remand supplemental claim" do
          subject
          expect(SupplementalClaim.where(decision_review_remanded: decision_document.appeal).count).to eq(1)
        end
      end

      context "when appellant is unrecognized" do
        let(:claimant) { create(:claimant, type: "OtherClaimant") }

        it "uploads the document and then gets blocked" do
          expect { subject }.to raise_error(NotImplementedError)

          expect(VBMSService).to have_received(:upload_document_to_vbms).with(
            decision_document.appeal, decision_document
          )
        end
      end

      it "uploads document" do
        subject

        expect(VBMSService).to have_received(:upload_document_to_vbms).with(
          decision_document.appeal, decision_document
        )

        expect(decision_document.uploaded_to_vbms_at).to eq(Time.zone.now)
      end

      context "when granted compensation issues" do
        let!(:granted_issue) do
          create(
            :decision_issue,
            :rating,
            disposition: "allowed",
            decision_review: decision_document.appeal
          )
        end

        let!(:another_granted_issue) do
          create(
            :decision_issue,
            :rating,
            description: "i am a long description" * 20,
            disposition: "allowed",
            decision_review: decision_document.appeal
          )
        end

        it "creates and processes effectuations" do
          subject

          expect(granted_issue.effectuation).to_not be_nil
          expect(granted_issue.effectuation).to have_attributes(
            appeal: decision_document.appeal,
            decision_document: decision_document,
            granted_decision_issue: granted_issue
          )

          expect(another_granted_issue.effectuation).to_not be_nil
          expect(denied_issue.effectuation).to be_nil

          # some extra broader assertions to make sure the end products are the same for both issues
          expect(granted_issue.effectuation.end_product_establishment).to_not be_nil
          expect(granted_issue.effectuation.end_product_establishment).to eq(
            another_granted_issue.effectuation.end_product_establishment
          )

          expect(VBMSService).to have_received(:establish_claim!).once.with(
            claim_hash: {
              benefit_type_code: decision_document.appeal.veteran.benefit_type_code,
              payee_code: "00",
              predischarge: false,
              claim_type: "Claim",
              station_of_jurisdiction: "397",
              date: decision_document.decision_date,
              end_product_modifier: "030",
              end_product_label: "Board Grant Rating",
              end_product_code: "030BGR",
              gulf_war_registry: false,
              suppress_acknowledgement_letter: false,
              claimant_participant_id: claimant_participant_id,
              limited_poa_code: nil,
              limited_poa_access: nil,
              status_type_code: "RFD"
            },
            veteran_hash: decision_document.appeal.veteran.to_vbms_hash,
            user: User.system_user
          )

          expect(another_granted_issue.contention_text.length).to eq(255)

          expect(VBMSService).to have_received(:create_contentions!).once.with(
            veteran_file_number: decision_document.appeal.veteran_file_number,
            claim_id: decision_document.end_product_establishments.last.reference_id,
            contentions: array_including(
              { description: granted_issue.contention_text,
                contention_type: Constants.CONTENTION_TYPES.default },
              description: another_granted_issue.contention_text,
              contention_type: Constants.CONTENTION_TYPES.default
            ),
            user: User.system_user,
            claim_date: decision_document.decision_date.to_date
          )

          expect(granted_issue.effectuation.contention_reference_id).to_not be_nil
          expect(another_granted_issue.effectuation.contention_reference_id).to_not be_nil

          expect(decision_document.attempted_at).to eq(Time.zone.now)
          expect(decision_document.processed_at).to eq(Time.zone.now)
        end

        context "when already processed" do
          let(:processed_at) { 2.hours.ago }

          it "does nothing" do
            subject

            expect(VBMSService).to_not have_received(:upload_document_to_vbms)
            expect(VBMSService).to_not have_received(:establish_claim!)
            expect(VBMSService).to_not have_received(:create_contentions!)
          end
        end

        context "when there was an error proccessing an effectuation" do
          before do
            allow(VBMSService).to receive(:create_contentions!).and_raise("Some VBMS contentions error")
          end

          it "does not record as processed" do
            expect { subject }.to raise_error("Some VBMS contentions error")

            expect(decision_document.uploaded_to_vbms_at).to eq(Time.zone.now)
            expect(decision_document.attempted_at).to eq(Time.zone.now)
            expect(decision_document.processed_at).to be_nil
            expect(decision_document.error).to eq("Some VBMS contentions error")
          end
        end
      end
    end

    context "when there was an upload error" do
      before do
        allow(VBMSService).to receive(:upload_document_to_vbms).and_raise("Some VBMS error")
      end

      it "saves document as attempted but not processed and saves the error" do
        expect { subject }.to raise_error("Some VBMS error")

        expect(decision_document.attempted_at).to eq(Time.zone.now)
        expect(decision_document.processed_at).to be_nil
        expect(decision_document.error).to eq("Some VBMS error")
      end
    end
  end
end
