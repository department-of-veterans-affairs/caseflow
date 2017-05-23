require "rails_helper"

describe Document do
  let(:document) { Document.new(type: "NOD", vbms_document_id: "123", received_at: received_at) }
  let(:file) { document.default_path }
  let(:received_at) { nil }

  context "#type?" do
    subject { document.type?("NOD") }

    context "when primary type matches" do
      let(:document) { Document.new(type: "NOD") }
      it { is_expected.to be_truthy }
    end

    context "when an alt type matches" do
      let(:document) { Document.new(type: "Form 9", alt_types: %w(SOC NOD)) }
      it { is_expected.to be_truthy }
    end

    context "when no types match" do
      let(:document) { Document.new(type: "Form 9", alt_types: ["SOC"]) }
      it { is_expected.to be_falsy }
    end
  end

  context "#receipt_date" do
    subject { document.receipt_date }

    context "when received_at is nil" do
      it { is_expected.to be_nil }
    end

    context "when received_at is a datetime" do
      let(:received_at) { Time.zone.now }
      it { is_expected.to eq(Time.zone.today) }
    end
  end

  context "#match_vbms_document_from" do
    subject { vacols_document.match_vbms_document_from(documents) }

    let(:vacols_document) { Document.new(type: "SOC", vacols_date: Time.zone.today + 2.days) }
    let(:date_mismatch) { Generators::Document.build(type: "SOC", received_at: 1.day.from_now) }
    let(:type_mismatch) { Generators::Document.build(type: "NOD", received_at: 2.days.from_now) }
    let(:match) { Generators::Document.build(type: "SOC", received_at: 2.days.from_now) }

    context "when there is a match" do
      let(:documents) { [date_mismatch, type_mismatch, match] }

      it { is_expected.to be_matching }
      it { is_expected.to have_attributes(received_at: match.received_at) }
    end

    context "when there isn't a match" do
      let(:documents) { [date_mismatch, type_mismatch] }

      it { is_expected.to_not be_matching }
    end
  end

  context "#fuzzy_match_vbms_document_from" do
    subject { vacols_document.fuzzy_match_vbms_document_from(documents) }

    let(:vacols_document) { Document.new(type: "SSOC", vacols_date: Time.zone.today) }
    let(:too_early) { Generators::Document.build(type: "SSOC", received_at: 5.days.ago) }
    let(:too_late) { Generators::Document.build(type: "SSOC", received_at: 1.day.from_now) }
    let(:type_mismatch) { Generators::Document.build(type: "NOD", received_at: 2.days.from_now) }
    let(:match) { Generators::Document.build(type: "SSOC", received_at: 4.days.ago) }

    context "when there is a match" do
      let(:documents) { [too_early, too_late, type_mismatch, match] }

      it { is_expected.to be_matching }
      it { is_expected.to have_attributes(received_at: match.received_at) }
    end

    context "when there isn't a match" do
      let(:documents) { [too_early, too_late, type_mismatch] }

      it { is_expected.to_not be_matching }
    end
  end

  context ".from_vbms_document" do
    subject { Document.from_vbms_document(vbms_document) }

    context "when has alt doc types" do
      let(:vbms_document) do
        OpenStruct.new(
          vbms_document_id: "1",
          doc_type: "179",
          received_at: "TEST",
          alt_doc_types: ["Appeals - Notice of Disagreement (NOD)", "Appeals - Statement of the Case (SOC)"]
        )
      end

      it { is_expected.to have_attributes(type: "Form 9", received_at: "TEST", alt_types: %w(NOD SOC)) }
    end

    context "when doesn't have alt doc types" do
      let(:vbms_document) do
        OpenStruct.new(
          vbms_document_id: "1",
          doc_type: "179",
          received_at: "TEST",
          alt_doc_types: nil
        )
      end

      it { is_expected.to have_attributes(type: "Form 9", received_at: "TEST") }
    end
  end

  context "content tests" do
    context "#fetch_and_cache_document_from_vbms" do
      it "loads document content" do
        expect(Fakes::AppealRepository).to receive(:fetch_document_file).and_return("content!")
        expect(document.fetch_and_cache_document_from_vbms).to eq("content!")
      end
    end

    context "#fetch_content" do
      before do
        S3Service.files = {}
      end

      it "lazy fetches document content" do
        expect(Fakes::AppealRepository).to receive(:fetch_document_file).exactly(1).times.and_return("content!")
        document.fetch_content
        expect(document.fetch_content).to eq("content!")
      end
    end

    context "#content" do
      before do
        S3Service.files = {}
      end

      it "lazy loads document content" do
        expect(Fakes::AppealRepository).to receive(:fetch_document_file).exactly(1).times.and_return("content!")
        document.content
        expect(document.content).to eq("content!")
      end
    end
  end

  context "#merge_into" do
    let(:from_vbms_document) do
      Generators::Document.build(
        type: "Form 9",
        alt_types: "Alt Form 9",
        received_at: Time.now.utc,
        filename: "test")
    end
    let(:persisted_document) { from_vbms_document.merge_into(Generators::Document.build) }

    it "fills the persisted document with data from the vbms document" do
      expect(from_vbms_document.type).to eq(persisted_document.type)
      expect(from_vbms_document.alt_types).to eq(persisted_document.alt_types)
      expect(from_vbms_document.received_at).to eq(persisted_document.received_at)
      expect(from_vbms_document.filename).to eq(persisted_document.filename)
    end
  end

  context "#serve!" do
    before do
      File.delete(file) if File.exist?(file)
      S3Service.files = {}
    end

    it "writes content to document" do
      expect(File.exist?(document.serve)).to be_truthy
    end
  end

  context "#file_name" do
    it "returns correct path" do
      expect(document.file_name).to match(/123/)
    end
  end

  context "#default_path" do
    it "returns correct path" do
      expect(document.default_path).to match(%r{.*\/tmp\/pdfs\/.*123})
    end
  end
end
