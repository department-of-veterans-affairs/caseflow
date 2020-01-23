# frozen_string_literal: true

describe CsvToS3Exporter do
  describe "#call", db_clean: :truncation do # explicit cleaner strategy so psql client sees transactions.
    after do
      File.unlink(temp_file) if File.exist?(temp_file)
      File.unlink(meta_file) if File.exist?(meta_file)
      fail "failed to clean up #{temp_file}" if File.exist?(temp_file)
      fail "failed to clean up #{meta_file}" if File.exist?(meta_file)
    end

    let(:temp_file) { File.join(Rails.root, "tmp", "appeals-to-s3.csv") }
    let(:meta_file) { "#{temp_file}.meta" }
    let(:today) { Time.zone.today.iso8601 }

    subject { described_class.new(test: temp_file, table: "appeals", bucket: "ignored").call }

    it "writes csv and meta files" do
      create(:appeal)

      meta = subject

      expect(meta[:rows]).to eq(1)
      expect(File.exist?(temp_file)).to eq(true)
      expect(File.exist?(meta_file)).to eq(true)

      meta_contents = File.read(meta_file)
      expect(JSON.parse(meta_contents, symbolize_names: true)).to eq(meta)
    end
  end
end
