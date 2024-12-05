# frozen_string_literal: true

RSpec.describe Hearings::CreateBillOfMaterialsJob do
  include ActiveJob::TestHelper

  let(:hearings) { (1..5).map { create(:hearing, :with_transcription_files) } }
  let(:legacy_hearings) { (1..5).map { create(:legacy_hearing, :with_transcription_files) } }

  def hearings_in_work_order(hearings)
    hearings.map { |hearing| { hearing_id: hearing.id, hearing_type: hearing.class.to_s } }
  end

  def cleanup_tmp
    %w(mp3 rtf zip xls json).each do |directory|
      dir = Dir.new("tmp/transcription_files/#{directory}")
      dir.each_child { |file_name| File.delete(dir.path + "/" + file_name) }
    end
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
  end

  after { cleanup_tmp }

  it "saves a bom file to tmp" do
    expect(Dir.empty?("tmp/transcription_files/json")).to eq true

    subject

    dir = Dir.new("tmp/transcription_files/json")

    expect(dir.children.count).to eq 1

    dir.each_child do |file_name|
      full_path = dir.path + "/" + file_name
      expect(File.exist?(full_path)).to eq true
      expect(File.extname(full_path)).to eq ".json"
    end
  end

  it "uploads the bom file to s3" do
    message = "File BOM-2030-0001.json successfully uploaded to " \
    "S3 location: vaec-appeals-caseflow-test/transcript_text/BOM-2030-0001.json"

    expect(Rails.logger).to receive(:info).with(message)

    subject
  end

  it "follows CycloneDX spec" do
    subject

    parsed_json = JSON.parse(File.read("tmp/transcription_files/json/BOM-2030-0001.json"), symbolize_names: true)
    metadata = parsed_json[:metadata]
    components = parsed_json[:components]

    expect(parsed_json[:bomFormat]).to eq "CycloneDX"
    expect(parsed_json[:specVersion]).to eq "1.3"
    expect(parsed_json[:serialNumber]).to be_a String
    expect(parsed_json[:version]).to eq 1
    expect(metadata).to be_a Hash
    expect(components).to be_an Array

    expect(metadata[:timestamp]).to be_a String
    expect(metadata[:tools]).to be_a Hash
    expect(metadata[:tools][:vendor]).to be_a String
    expect(metadata[:tools][:name]).to be_a String
    expect(metadata[:tools][:version]).to be_a String
    expect(metadata[:tools][:hashes]).to be_a Array
    expect(metadata[:tools][:hashes][0][:alg]).to eq "MD5"
    expect(metadata[:tools][:hashes][0][:content]).to be_a String
    expect(metadata[:tools][:authors]).to be_an Array
    expect(metadata[:tools][:authors][0][:name]).to be_a String
    expect(metadata[:tools][:authors][0][:email]).to be_a String
    expect(metadata[:component]).to be_a Hash
    expect(metadata[:component][:type]).to be_a String
    expect(metadata[:component][:name]).to be_a String
    expect(metadata[:component][:version]).to be_a String
    expect(metadata[:supplier]).to be_a Hash
    expect(metadata[:supplier][:name]).to be_a String
    expect(metadata[:supplier][:url]).to be_a String
    expect(metadata[:supplier][:contact]).to be_a Hash
    expect(metadata[:supplier][:contact][:name]).to be_a String
    expect(metadata[:supplier][:contact][:email]).to be_a String

    components.each do |hash|
      expect(hash[:type]).to be_a String
      expect(hash[:"bom-ref"]).to be_a String
      expect(hash[:author]).to be_a String
      expect(hash[:name]).to be_a String
      expect(hash[:version]).to be_a String
      expect(hash[:description]).to be_a String
      expect(hash[:hashes]).to be_a Array
      expect(hash[:hashes][0][:alg]).to eq "MD5"
      expect(hash[:hashes][0][:content]).to be_a String
      expect(hash[:licenses]).to be_a Array
      expect(hash[:licenses][0][:license]).to be_a Hash
      expect(hash[:licenses][0][:license][:id]).to be_a String
      expect(hash[:licenses][0][:license][:text]).to be_a Hash
      expect(hash[:licenses][0][:license][:text][:contentType]).to be_a String
      expect(hash[:licenses][0][:license][:text][:encoding]).to be_a String
      expect(hash[:purl]).to be_a String
    end
  end

  it "retries on aws upload failure" do
    allow_any_instance_of(described_class).to receive(:perform)
      .and_raise(TranscriptionFileUpload::FileUploadError)

    perform_enqueued_jobs do
      expect { subject }.to raise_error(
        Hearings::CreateBillOfMaterialsJob::BomFileUploadError
      )
    end
  end
end
