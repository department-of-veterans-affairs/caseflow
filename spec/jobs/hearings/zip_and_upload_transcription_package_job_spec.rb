# frozen_string_literal: true

RSpec.describe Hearings::ZipAndUploadTranscriptionPackageJob do
  include ActiveJob::TestHelper

  let(:hearings) { (1..5).map { create(:hearing, :with_transcription_files) } }
  let(:legacy_hearings) { (1..5).map { create(:legacy_hearing, :with_transcription_files) } }

  def hearings_in_work_order(hearings)
    hearings.map { |hearing| { hearing_id: hearing.id, hearing_type: hearing.class.to_s } }
  end

  def cleanup_tmp
    directories = %w(mp3 rtf zip xls json)
    base_path = "tmp/transcription_files"

    directories.each do |directory|
      dir_path = File.join(base_path, directory)

      next if Dir.exist?(dir_path)

      Dir.children(dir_path).each do |file_name|
        file_path = File.join(dir_path, file_name)

        begin
          File.delete(file_path)
        rescue StandardError => error
          { error: error.message }
        end
      end
    end
  end

  def take_bom_file
    last_file = Dir.glob("tmp/transcription_files/zip/*").max_by { |f| File.mtime(f) }
    File.basename(last_file)
  end

  let(:work_order) do
    {
      work_order_name: "BVA-2030-0001",
      return_date: "05-01-2023",
      contractor_name: TranscriptionContractor.first&.name,
      hearings: hearings_in_work_order(hearings + legacy_hearings)
    }
  end

  subject { described_class.perform_now(work_order) }

  before do
    Seeds::TranscriptionContractors.new.seed!
    Hearings::WorkOrderFileJob.perform_now(work_order)
    Hearings::ZipAndUploadTranscriptionFilesJob.perform_now(work_order[:hearings])
    Hearings::CreateBillOfMaterialsJob.perform_now(work_order)
  end

  after { cleanup_tmp }

  it "saves a transcription Package Zip file to tmp" do
    expect(Dir.empty?("tmp/transcription_files/zip")).to eq false

    dir = Dir.new("tmp/transcription_files/zip")
    total_file = dir.children.count

    expect(dir.children.count).to eq total_file
    subject

    expect(dir.children.count).to eq total_file + 1
    file_name = take_bom_file
    expect(file_name).to match(%r{BVA\w{1,2}-\d{4}-\d{4}.zip})
    full_path = "#{dir.path}/#{file_name}"
    expect(File.exist?(full_path)).to eq true
    expect(File.extname(full_path)).to eq ".zip"
  end

  it "uploads the bom file to s3" do
    message = "File successfully uploaded to S3 location"

    expect(Rails.logger).to receive(:info).with(message)

    subject
  end

  it "creates a transcription package record for file" do
    subject

    TranscriptionPackage.where(task_number: work_order[:work_order_name]).each do |current_entry|
      expect(current_entry.aws_link_zip).to be_a String
      expect(current_entry.aws_link_work_order).to be_a String
      expect(current_entry.created_by_id).to be_a Integer
      expect(current_entry.status).to eq "Successful upload (AWS)"
      expect(current_entry.contractor_id).to be_a Integer
    end
  end
end
