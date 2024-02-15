# frozen_string_literal: true

require "rails_helper"

describe TranscriptionTransformer do
  let(:hearing_info) { { date: Time.zone.today, judge: "John Smith", appeal_id: "100000001" } }
  let(:subject) { transformer.call }

  describe "#call" do
    context "errors" do
      context "vtt doesn't exist" do
        let(:path) { "/this/does/not/exist" }
        let(:transformer) { TranscriptionTransformer.new(path, hearing_info) }

        it "raises a HearingConversionError" do
          expect { subject }.to raise_error(TranscriptionTransformer::FileConversionError)
        end
      end

      context "file is malformed or unreadable" do
        let(:file_name) { ["foo", ".vtt"] }
        let(:file) { Tempfile.new(file_name) }
        let(:transformer) { TranscriptionTransformer.new(file.path, hearing_info) }
        it "raises a HearingConversionError" do
          expect { subject }.to raise_error(TranscriptionTransformer::FileConversionError)
        end
      end
    end
  end

  describe "successful conversion" do
    let(:file_name) { ["foo", ".vtt"] }
    let(:file) { Tempfile.new(file_name) }
    let(:transformer) { TranscriptionTransformer.new(file.path, hearing_info) }
    let(:doc) { RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, "Times New Roman")) }
    let(:rtf_path) { file.path.gsub("vtt", "rtf") }

    before do
      allow_any_instance_of(TranscriptionTransformer).to receive(:convert_to_rtf).and_return(rtf_path)
    end

    it "returns the file path of rtf" do
      allow(WebVTT).to receive(:read).and_return(file)
      allow(transformer).to receive(:create_transcription_pages).and_return(doc)
      subject
    end

    describe "csv creation" do
      let(:csv_path) { file.path.gsub("vtt", "csv") }

      it "will not create csv if no errors detected" do
        expect(transformer).to_not receive(:build_csv)
        expect(subject).to eq([rtf_path])
      end

      it "will create csv if errors are detected" do
        transformer.instance_variable_set(:@length, 1000)
        transformer.instance_variable_set(:@error_count, 2)
        expect(subject).to eq([rtf_path, csv_path])
      end
    end
  end
end
