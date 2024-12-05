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

  describe "convert_to_rtf!" do
    let(:tmp_location) { file.tmp_location }

    it "converts to rtf successfully" do
      File.open(tmp_location, "w") do |f|
        f.puts "WEBVTT"
        f.puts ""
        f.puts "1"
        f.puts "00:02:15.000 --> 00:02:20.000"
        f.puts "- Test text."
        f.close
      end

      expect(file.convert_to_rtf!).to eq([tmp_location.gsub("vtt", "rtf")])

      File.delete(tmp_location)
      File.delete(tmp_location.gsub("vtt", "rtf"))
    end

    it "handles exceptions with grace and poise" do
      expect { file.convert_to_rtf! }.to raise_error(TranscriptionTransformer::FileConversionError)
    end
  end

  describe "lockable?" do
    before do
      @current_time = Time.zone.local(2024, 1, 17, 15, 37, 0).utc
      Timecop.freeze(@current_time)
    end

    it "returns true if the record was locked by the current user" do
      file.locked_by_id = 1
      file.locked_at = @current_time - 1.hour
      expect(file.lockable?(1)).to be_truthy
    end

    it "returns true if the record was locked by another user more than two hours ago" do
      file.locked_by_id = 1
      file.locked_at = @current_time - 2.hours - 1.minute
      expect(file.lockable?(2)).to be_truthy
    end

    it "returns false if the record was locked by another user less than two hours ago" do
      file.locked_by_id = 1
      file.locked_at = @current_time - 2.hours
      expect(file.lockable?(2)).to be_falsy
    end
  end

  describe "search" do
    let!(:t_1) { create(:transcription, task_number: "BVA2024001") }
    let!(:t_2) { create(:transcription, task_number: "BVA2024002") }
    let!(:t_3) { create(:transcription, task_number: "BVA2024003") }
    let!(:t_4) { create(:transcription, task_number: "BVA2024004") }

    let!(:tf_1) { create(:transcription_file, transcription: t_1) }
    let!(:tf_2) { create(:transcription_file, transcription: t_2) }
    let!(:tf_3) { create(:transcription_file, transcription: t_3) }
    let!(:tf_4) { create(:transcription_file, transcription: t_4) }

    it "searches on docket number" do
      query = tf_1.docket_number
      @transcription_files = TranscriptionFile.filterable_values.search(query)

      expect(@transcription_files.length).to be(1)
      expect(@transcription_files[0].id).to eq(tf_1.id)
    end

    it "searches on people first and last name" do
      query = tf_2.hearing.appeal.claimant.person.first_name + " " + tf_2.hearing.appeal.claimant.person.last_name
      @transcription_files = TranscriptionFile.filterable_values.search(query)

      expect(@transcription_files.length).to be(1)
      expect(@transcription_files[0].id).to eq(tf_2.id)
    end

    it "searches on veterans first and last name" do
      query = tf_3.hearing.appeal.veteran.first_name + " " + tf_3.hearing.appeal.veteran.last_name
      @transcription_files = TranscriptionFile.filterable_values.search(query)

      expect(@transcription_files.length).to be(1)
      expect(@transcription_files[0].id).to eq(tf_3.id)
    end

    it "searches on veterans file number" do
      query = tf_4.hearing.appeal.veteran.file_number
      @transcription_files = TranscriptionFile.filterable_values.search(query)

      expect(@transcription_files.length).to be(1)
      expect(@transcription_files[0].id).to eq(tf_4.id)
    end

    it "searches on task_number" do
      query = "BVA2024002"
      @transcription_files = TranscriptionFile.filterable_values.search(query)

      expect(@transcription_files.length).to be(1)
      expect(@transcription_files[0].id).to eq(tf_2.id)
    end
  end
end
