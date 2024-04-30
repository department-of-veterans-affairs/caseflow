# frozen_string_literal: true

RSpec.describe Hearings::ZipAndUploadTranscriptionFilesJob do
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

  subject { described_class.new.perform(hearings_in_work_order(hearings + legacy_hearings)) }

  after { cleanup_tmp_directories }

  it "temporarily downloads mp3s and rtfs for all the hearings in a work order" do
    allow_any_instance_of(described_class).to receive(:cleanup_tmp).and_return(nil)

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
    allow_any_instance_of(described_class).to receive(:cleanup_tmp).and_return(nil)

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
end
