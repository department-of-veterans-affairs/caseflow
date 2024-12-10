# frozen_string_literal: true

RSpec.describe Hearings::MonitorBoxJob, type: :job do
  describe "#poll_box_dot_com_for_new_files" do
    subject { described_class.new.poll_box_dot_com_for_new_files }

    before do
      allow(ExternalApi::VaBoxService).to receive(:new)
        .and_return(Fakes::VaBoxService.new)
    end

    # see data setup in Fakes::VaBoxService for expectations
    it "returns an array of hashes with name, id, created_at, modified_at" do
      expect(subject).to be_an(Array)
      expect(subject.empty?).to eq(false)
      subject.each do |hash|
        expect(hash).to have_key(:id)
        expect(hash).to have_key(:name)
        expect(hash).to have_key(:created_at)
        expect(hash).to have_key(:modified_at)
      end
    end

    it "returns AMA hearing files" do
      file_names = subject.map { |file| file[:name] }
      expect(file_names.any?("123456-1_5678_Hearing.doc")).to eq(true)
    end

    it "returns legacy hearing files" do
      file_names = subject.map { |file| file[:name] }
      expect(file_names.any?("1234567_2342_LegacyHearing.pdf")).to eq(true)
    end

    it "returns work order files" do
      file_names = subject.map { |file| file[:name] }
      expect(file_names.any?("BVA-2024-0001.xls")).to eq(true)
    end

    # the file with the name "654321-1_1234_Hearing.doc" has the
    # correct naming convention, but it's created_at value is
    # outside the allowed time range
    it "only returns most recently added files" do
      file_names = subject.map { |file| file[:name] }
      expect(file_names.any?("654321-1_1234_Hearing.doc")).to eq(false)
    end

    # the file with the name "NOT_THE_CORRECT_NAMING_CONVENTION.zip" has
    # a created_at value within the allowed time range, but the name
    # doesn't follow the Webex naming convention
    it "only returns files with webex naming convention" do
      file_names = subject.map { |file| file[:name] }
      expect(file_names.any?("NOT_THE_CORRECT_NAMING_CONVENTION.zip")).to eq(false)
    end
  end
end
