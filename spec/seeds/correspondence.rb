# frozen_string_literal: true

describe Seeds::Correspondence do
  let(:seed) { Seeds::Correspondence.new }

  describe "initial values" do
    it "are set properly" do
      expect(seed.instance_variable_get(:@file_number)).to eq 500_000_000
      expect(seed.instance_variable_get(:@participant_id)).to eq 850_000_000
    end

    it "are set properly when seed has been previously run" do
      veteran = Veteran.create!(file_number: 500_000_001)
      Correspondence.create!(veteran_id: veteran.id)

      expect(seed.instance_variable_get(:@file_number)).to eq 500_000_100
      expect(seed.instance_variable_get(:@participant_id)).to eq 850_000_100
    end
  end

  describe "#seed!" do
    it "creates a bunch of correspondences with one document each" do
      seed.seed!
      expect(Correspondence.count).to eq(128)
      expect(Correspondence.first.correspondence_documents.count).to eq(1)
      expect(Correspondence.last.correspondence_documents.count).to eq(1)
      expect(CorrespondenceDocument.count).to eq(128)
    end
  end
end
