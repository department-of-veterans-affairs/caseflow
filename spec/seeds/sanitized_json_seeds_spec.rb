# frozen_string_literal: true

describe Seeds::SanitizedJsonSeeds do
  describe "#seed!" do
    subject { described_class.new.seed! }
    let(:sji1) { instance_double(SanitizedJsonImporter) }
    let(:sji2) { instance_double(SanitizedJsonImporter) }

    it "creates appeals ready for substitution" do
      expect { subject }.to_not raise_error

      # This refers specifically to appeal_with_substitution_1.json, but confirms this truly works.
      expect(Appeal.where(uuid: '9c14a2fd-348e-44d0-9465-5c3c6303b52d').count).to eq 1
    end

    it "invokes SanitizedJsonImporter for each matching file" do
      expect(Dir).to receive(:glob).with("db/seeds/sanitized_json/*.json").
        and_return(%w[a_file.json another_file.json])

      expect(SanitizedJsonImporter).to receive(:from_file).
        with("a_file.json", {verbosity: 0}).and_return(sji1)
      expect(sji1).to receive(:import)

      expect(SanitizedJsonImporter).to receive(:from_file).
        with("another_file.json", {verbosity: 0}).and_return(sji2)
      expect(sji2).to receive(:import)

      subject
    end
  end
end
