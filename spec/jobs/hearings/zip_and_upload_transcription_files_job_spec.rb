# frozen_string_literal: true

RSpec.describe Hearings::ZipAndUploadTranscriptionFilesJob do
  include ActiveJob::TestHelper

  def hearings_in_work_order(hearings)
    hearings.map { |hearing| { hearing_id: hearing.id, hearing_type: hearing.class.to_s } }
  end

  def cleanup_tmp_directories
    %w(mp3 rtf zip).each do |directory|
      dir = Dir.new("tmp/transcription_files/#{directory}")
      dir.each_child { |file_name| File.delete(dir.path + "/" + file_name) }
    end
  end

  let(:hearings) { (1..5).map { create(:hearing, :with_transcription_files) } }
  let(:legacy_hearings) { (1..5).map { create(:legacy_hearing, :with_transcription_files) } }

  subject { described_class.perform_now(hearings_in_work_order(hearings + legacy_hearings)) }

  before { User.authenticate!(user: create(:user)) }

  after { cleanup_tmp_directories }

  it "temporarily downloads mp3s and rtfs for all the hearings in a work order" do
    allow_any_instance_of(described_class).to receive(:cleanup_tmp_files).and_return(nil)

    %w(mp3 rtf).each do |directory|
      expect(Dir.empty?("tmp/transcription_files/#{directory}")).to eq(true)
    end

    subject

    %w(mp3 rtf).each do |directory|
      dir = Dir.new("tmp/transcription_files/#{directory}")
      expect(Dir.empty?(dir.path)).to eq(false)
      dir.each_child do |file_name|
        expect(File.exist?(dir.path + "/" + file_name)).to eq true
      end
    end
  end

  it "temporarily saves a zip file for each hearing in the work order" do
    allow_any_instance_of(described_class).to receive(:cleanup_tmp_files).and_return(nil)

    expect(Dir.empty?("tmp/transcription_files/zip")).to eq true

    subject

    dir = Dir.new("tmp/transcription_files/zip")
    expect(dir.children.count).to eq(hearings.count + legacy_hearings.count)
    dir.each_child do |file_name|
      full_path = dir.path + "/" + file_name
      expect(File.exist?(full_path)).to eq true
      expect(File.extname(full_path)).to eq ".zip"
    end
  end

  it "creates a transcription file record for each zip file" do
    expect(TranscriptionFile.where(file_type: "zip").empty?).to eq true

    subject

    TranscriptionFile.where(file_type: "zip").each do |file|
      expect(file.file_name).to be_a String
      expect(file.date_upload_aws).to be_a Time
      expect(file.created_by_id).to be_a Integer
      expect(file.aws_link).to be_a String
    end
  end

  it "uploads the zip file to s3 bucket" do
    subject

    TranscriptionFile.where(file_type: "zip").pluck("aws_link").each do |link|
      expect(link.include?("vaec-appeals-caseflow-test/transcript_text")).to eq true
    end
  end

  context "fails to upload to s3" do
    it "retries on failure to upload to s3" do
      allow_any_instance_of(described_class).to receive(:perform)
        .and_raise(TranscriptionFileUpload::FileUploadError)

      perform_enqueued_jobs do
        expect { subject }.to raise_error(
          Hearings::ZipAndUploadTranscriptionFilesJob::ZipFileUploadError
        )
      end
    end
  end
end
