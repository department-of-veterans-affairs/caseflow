# frozen_string_literal: true

require "rails_helper"

describe TranscriptionTransformer do
  describe "#call" do
    context "errors" do
      context "vtt doesn't exist" do
        let(:path) { "/this/does/not/exist" }
        let(:transformer) { TranscriptionTransformer.new(path) }

        it "raises a HearingConversionError" do
          expect { transformer.call }.to raise_error(TranscriptionTransformer::FileConversionError)
        end
      end

      context "file is malformed or unreadable" do
        let(:file_name) { ["foo", ".vtt"] }
        let(:file) { Tempfile.new(file_name) }
        let(:transformer) { TranscriptionTransformer.new(file.path) }
        it "raises a HearingConversionError" do
          expect { transformer.call }.to raise_error(TranscriptionTransformer::FileConversionError)
        end
      end
    end
  end
  describe "valid file path" do
    let(:file_name) { ["foo", ".vtt"] }
    let(:file) { Tempfile.new(file_name) }
    let(:transformer) { TranscriptionTransformer.new(file.path) }
    let(:doc) { RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, "Times New Roman")) }
    let(:rtf_path) { file.path.gsub("vtt", "rtf") }

    it "returns the file path of rtf" do
      allow(WebVTT).to receive(:read).and_return(file)
      allow(transformer).to receive(:create_transcription_pages).and_return(doc)
      transformer.call
    end
  end
end
