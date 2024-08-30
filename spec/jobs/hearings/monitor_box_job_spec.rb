# frozen_string_literal: true

RSpec.describe Hearings::MonitorBoxJob, type: :job do
  describe "#perform" do
    subject { described_class.perform_now }

    before do
      allow(ExternalApi::VaBoxService).to receive(:new)
        .and_return(Fakes::VaBoxService.new)
    end

    # see data setup in Fakes::VaBoxService for expectations
    it "returns an array of hashes with name, id, created_at, modified_at" do
      expect(subject).to be_an(Array)
      subject.each do |hash|
        expect(hash).to have_key(:id)
        expect(hash).to have_key(:name)
        expect(hash).to have_key(:created_at)
        expect(hash).to have_key(:modified_at)
      end
    end

    it "only returns most recently added files" do
      # the file with the name "654321-1234-1234-AMA.zip" has the
      # correct naming convention, but it's created_at value is
      # outside the allowed time range
      file_names = subject.map { |file| file[:name] }
      expect(file_names.any?("654321-1234-1234-AMA.zip")).to eq(false)
    end

    it "only returns files with webex naming convention" do
      # the file with the name "NOT_THE_CORRECT_NAMING_CONVENTION.zip" has
      # a created_at value within the allowed time range, but the name
      # doesn't follow the Webex naming convention
      file_names = subject.map { |file| file[:name] }
      expect(file_names.any?("NOT_THE_CORRECT_NAMING_CONVENTION.zip")).to eq(false)
    end
  end
end
