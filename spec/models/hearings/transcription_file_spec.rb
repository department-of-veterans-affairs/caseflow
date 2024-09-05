# frozen_string_literal: true

require "rails_helper"

describe TranscriptionFile do
  let(:file) { create(:transcription_file) }
  let(:uploaded_file) { create(:transcription_file, :uploaded) }

  before do
    RequestStore[:current_user] = User.system_user
  end

  describe "model functions" do
    it "downloading a file" do
      expect(uploaded_file.fetch_file_from_s3!).to eq("#{Rails.root}/tmp/transcription_files/vtt/transcript.vtt")
    end

    it "uploading a file" do
      file.upload_to_s3!
      expect(file.aws_link).not_to be(nil)
    end
  end

  describe "tmp files" do
    let(:tmp_location) { file.tmp_location }
    let(:temp) { Tempfile.new(tmp_location) }

    it "cleaning up tmp location" do
      temp
      expect(File.exist?(tmp_location)).to eq(true)
      file.clean_up_tmp_location
      expect(File.exist?(tmp_location)).to eq(false)
    end
  end
end
