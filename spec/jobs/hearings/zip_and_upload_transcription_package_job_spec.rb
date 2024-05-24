# frozen_string_literal: true

RSpec.describe Hearings::ZipAndUploadTranscriptionPackageJob do
  include ActiveJob::TestHelper

  let(:hearings) { (1..1).map { create(:hearing, :with_transcription_files) } }
  let(:legacy_hearings) { (1..1).map { create(:legacy_hearing, :with_transcription_files) } }

  def hearings_in_work_order(hearings)
    hearings.map { |hearing| { hearing_id: hearing.id, hearing_type: hearing.class.to_s } }
  end

  def cleanup_tmp
    %w(mp3 rtf zip xls json).each do |directory|
      dir = Dir.new("tmp/transcription_files/#{directory}")
      dir.each_child { |file_name| File.delete("#{dir.path}/#{file_name}") }
    end
  end

  def take_bom_file
    last_file = Dir.glob("tmp/transcription_files/zip/*").max_by { |f| File.mtime(f) }
    File.basename(last_file)
  end

  let(:work_order) do
    {
      work_order_name: "BVA-2030-0001",
      return_date: "xx-xx-xxxx",
      contractor_name: "Bob's contract house",
      hearings: hearings_in_work_order(hearings + legacy_hearings)
    }
  end

  subject { described_class.perform_now(work_order) }

  before do
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

    # last_file = Dir.glob("tmp/transcription_files/zip/*").max_by {|f| File.mtime(f)}
    # file_name = File.basename(last_file)
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

  # it "Create new entry in TranscriptionPackage table" do
  # end

end
