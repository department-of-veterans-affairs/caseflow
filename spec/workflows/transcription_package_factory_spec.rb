# frozen_string_literal: true

describe TranscriptionPackageFactory, :postgres do
  describe "#initialize" do
    let(:user) { create(:user) }
    it "creates transcription_packages record" do
      expect(TranscriptionPackage.count).to eq 0
      TranscriptionPackageFactory.new("#12345", user.id, DateTime.now)
      TranscriptionPackageFactory.new("#6780", user.id, DateTime.now)
      expect(TranscriptionPackage.count).to eq 2
    end
  end
end
