# frozen_string_literal: true

require "rails_helper"

describe TranscriptionTransformer do
  let(:hearing) { create(:hearing) }

  describe "#call" do
    context "errors" do
      context "vtt doesn't exist" do
        let(:path) { "/this/does/not/exist" }
        let(:transformer) { TranscriptionTransformer.new(path, hearing) }

        it "raises a HearingConversionError" do
          expect { transformer.call }.to raise_error(TranscriptionTransformer::FileConversionError)
        end
      end

      context "file is malformed or unreadable" do
        let(:file_name) { ["foo", ".vtt"] }
        let(:file) { Tempfile.new(file_name) }
        let(:transformer) { TranscriptionTransformer.new(file.path, hearing) }
        it "raises a HearingConversionError" do
          expect { transformer.call }.to raise_error(TranscriptionTransformer::FileConversionError)
        end
      end
    end
  end
  describe "successful conversion" do
    let(:file_name) { ["foo", ".vtt"] }
    let(:file) { Tempfile.new(file_name) }
    let(:transformer) { TranscriptionTransformer.new(file.path, hearing) }
    let(:doc) { RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, "Times New Roman")) }
    let(:rtf_path) { file.path.gsub("vtt", "rtf") }

    before do
      allow_any_instance_of(TranscriptionTransformer).to receive(:convert_to_rtf).and_return([rtf_path])
    end

    it "returns the file path of rtf" do
      allow(WebVTT).to receive(:read).and_return(file)
      allow(transformer).to receive(:create_transcription_pages).and_return(doc)
      transformer.call
    end
  end
end
