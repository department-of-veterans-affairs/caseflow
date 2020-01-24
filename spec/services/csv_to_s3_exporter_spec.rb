# frozen_string_literal: true

describe CsvToS3Exporter do
  subject { described_class.new(test: temp_file, table: "appeals", bucket: "ignored") }

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

    let!(:appeal) { create(:appeal) }

    it "writes csv and meta files" do
      meta = subject.call

      expect(meta[:rows]).to eq(1)
      expect(File.exist?(temp_file)).to eq(true)
      expect(File.exist?(meta_file)).to eq(true)

      meta_contents = File.read(meta_file)
      expect(JSON.parse(meta_contents, symbolize_names: true)).to eq(meta)
    end

    context "external shell commands missing or exit with non-zero" do
      it "raises error" do
        allow(subject).to receive(:run).and_call_original
        allow(subject).to receive(:run).with(/wc -l /).and_wrap_original do |m|
          m.call("false")
        end

        expect { subject.call }.to raise_error(CsvToS3Exporter::ShellError)
      end
    end

    context "line count mismatch" do
      it "raises CsvError" do
        allow(subject).to receive(:run).and_call_original
        allow(subject).to receive(:run).with(/wc -l /) { "123" }

        expect { subject.call }.to raise_error(CsvToS3Exporter::CsvError)
      end
    end

    context "with live aws s3 cp" do
      before do
        allow(subject).to receive(:run).and_call_original
        allow(subject).to receive(:run).with(/aws --region/) { true }
      end

      subject { described_class.new(table: "appeals", bucket: "bucket-name", date: "the-date") }

      it "receives expected bucket path" do
        expect(subject).to receive(:run).with(/s3:\/\/bucket-name\/the-date\/the-date-caseflow-appeals.csv.gz/)

        subject.call
      end

      context "with compress:false" do
        subject { described_class.new(table: "appeals", bucket: "bucket-name", date: "the-date", compress: false) }

        it "does not compress" do
          expect(subject).to receive(:run).with(/s3:\/\/bucket-name\/the-date\/the-date-caseflow-appeals.csv/)

          subject.call
        end
      end
    end
  end
end
