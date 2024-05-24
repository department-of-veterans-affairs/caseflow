# frozen_string_literal: true

describe "TranscriptionPackage" do
  let(:transcription_package) { create(:transcription_package) }

  it "creates transcription_packages record" do
    expect(TranscriptionPackage.count).to eq 0
    transcription_package
    expect(TranscriptionPackage.count).to eq 1
  end
end
