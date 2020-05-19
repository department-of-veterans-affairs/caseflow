# frozen_string_literal: true

describe DuplicateVeteranParticipantIDFinder, :postgres do
  let(:bgs) { ExternalApi::BGSService.new(client: bgs_client) }
  let(:bgs_client) { double("bgs") }
  let(:people_service) { double("people") }
  let(:ssn) { "987654321" }
  let(:file_number) { "111111111S" }
  let(:participant_id) { "123456" }
  let(:second_participant_id) { "765432" }
  let(:veteran) do
    create(:veteran, ssn: ssn, participant_id: participant_id, file_number: file_number)
  end
  let(:bgs_veteran_record) do
    {
      ptcpnt_id: participant_id,
      file_number: file_number,
      ssn: ssn
    }
  end

  before do
    allow(bgs_client).to receive(:people) { people_service }
    allow(people_service).to receive(:find_by_ssn) do
     { ptcpnt_id: second_participant_id }
    end
    allow(bgs).to receive(:fetch_veteran_info).with(file_number) { bgs_veteran_record }
    allow(BGSService).to receive(:new) { bgs }
  end

  describe "#call" do
    subject { described_class.new(veteran: veteran).call }

    it "returns duplicate participant IDs" do
      expect(subject).to match_array [participant_id, second_participant_id]
    end
  end
end
