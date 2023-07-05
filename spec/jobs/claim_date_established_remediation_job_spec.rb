# frozen_string_literal: true

describe ClaimDateEstablishedRemediationJob, :postgres do
  let(:error_text) { "Claim not established" }
  let!(:file_number) { "987654321" }
  let!(:veteran) { create(:veteran, file_number: file_number) }
  let!(:appeal) { create(:appeal, veteran_file_number: file_number) }
  let!(:decision_document_with_error) { create(:decision_document, error: error_text, appeal: appeal) }
  let!(:epe) do
    create(:end_product_establishment, established_at: Time.zone.now, code: "030",
                                       veteran_file_number: file_number)
  end
  let!(:file_number_2) { "123456789" }
  let!(:veteran_2) { create(:veteran, file_number: file_number_2) }
  let!(:appeal_2) { create(:appeal, veteran_file_number: file_number_2) }
  let!(:decision_document_with_error_2) { create(:decision_document, error: error_text, appeal: appeal_2) }
  let!(:epe_2) do
    create(:end_product_establishment, established_at: Time.zone.now, code: "040",
                                       veteran_file_number: file_number_2)
  end

  let!(:file_number_3) { "383828282" }
  let!(:veteran_3) { create(:veteran, file_number: file_number_3) }
  let!(:appeal_3) { create(:appeal, veteran_file_number: file_number_3) }
  let!(:decision_document_with_error_3) { create(:decision_document, error: error_text, appeal: appeal_3) }
  let!(:epe_3) do
    create(:end_product_establishment, established_at: Time.zone.now, code: "060",
                                       veteran_file_number: file_number_3)
  end

  before do
    allow(subject).to receive(:upload_logs_to_s3).with(anything).and_return("logs")
  end

  subject { ClaimDateEstablishedRemediationJob.new }

  context "when all necessary fields on epe are populated" do
    it "clears the error field of the DD" do
      create_list(:decision_document, 5)
      expect(subject.decision_document_with_errors.count).to eq(3)

      subject.perform

      expect(subject.decision_document_with_errors.count).to eq(1)
      expect(decision_document_with_error.reload.error).to be_nil
      expect(decision_document_with_error_2.reload.error).to be_nil
      expect(decision_document_with_error_3.reload.error).not_to be_nil
    end
  end

  context "when some of the necessary fields are not populated" do
    describe "when code is nil" do
      it "does not clear the error field on the Decision Document" do
        epe.update(code: nil)
        subject.perform
        expect(decision_document_with_error.reload.error).to include(error_text)
      end
    end
    describe "when established_at is nil" do
      it "does not clear the error field on the Decision Document" do
        epe.update(established_at: nil)
        subject.perform
        expect(decision_document_with_error.reload.error).to include(error_text)
      end
    end
  end
end
