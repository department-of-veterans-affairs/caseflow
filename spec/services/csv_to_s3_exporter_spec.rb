# frozen_string_literal: true

describe CsvToS3Exporter do
  describe "#call", skip_db_cleaner: true do # skip cleaner so our data is available to psql CLI
    after do
      File.unlink(temp_file)
      File.unlink(meta_file)
      fail "failed to clean up #{temp_file}" if File.exists?(temp_file)
      fail "failed to clean up #{meta_file}" if File.exists?(meta_file)
    end

    let(:temp_file) { Tempfile.new.path }
    let(:meta_file) { "#{temp_file}.meta" }
    let(:today) { Time.zone.today.iso8601 }

    subject { described_class.new(test: temp_file, table: "appeals", bucket: "ignored" ).call }

    it "writes csv and meta files" do
      create(:appeal)

      meta = subject

      expect(meta[:rows]).to eq(1)
      expect(File.exists?(temp_file)).to eq(true)
      expect(File.exists?(meta_file)).to eq(true)

      meta_contents = File.read(meta_file)
      expect(JSON.parse(meta_contents, symbolize_names: true)).to eq(meta)
    end
  end
end
