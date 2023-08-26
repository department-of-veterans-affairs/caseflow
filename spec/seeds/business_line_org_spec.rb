# frozen_string_literal: true

describe Seeds::BusinessLineOrg do
  describe "#seeds!" do
    subject { described_class.new.seed! }
    let(:sji1) { instance_double(SanitizedJsonImporter) }

    it "reads json file from specific directory" do
      expect(subject).to eq ["db/seeds/sanitized_business_line_json/business_line.json"]
    end

    it "creates business line organizations" do
      expect { subject }.to_not raise_error
      expect(BusinessLine.count).to eq 9
    end

    it "invokes SanitizedJsonImporter for each matching file" do
      expect(Dir).to receive(:glob).with("db/seeds/sanitized_business_line_json/business_line.json")
        .and_return(%w[business_line.json])

      expect(SanitizedJsonImporter).to receive(:from_file)
        .with("business_line.json", verbosity: 0).and_return(sji1)
      expect(sji1).to receive(:import)

      subject
    end
  end
end
