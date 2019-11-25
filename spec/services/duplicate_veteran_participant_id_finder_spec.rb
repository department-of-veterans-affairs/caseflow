# frozen_string_literal: true

describe DuplicateVeteranParticipantIDFinder, :postgres do
  it "returns duplicate participant IDs" do
    stub_const("BGSService", ExternalApi::BGSService)
    RequestStore[:current_user] = create(:user)

    ssn = "987654321"
    file_number = "111111111S"
    participant_id = "123456"
    second_participant_id = "765432"
    veteran = create(:veteran, ssn: ssn, participant_id: participant_id, file_number: file_number)

    allow(Veteran).to receive(:find_or_create_by_file_number).and_return(veteran)
    allow(veteran).to receive(:fetch_bgs_record).and_return({})
    allow_any_instance_of(BGS::PersonWebService).to receive(:find_by_ssn).and_return(ptcpnt_id: second_participant_id)

    pids = DuplicateVeteranParticipantIDFinder.new(veteran: veteran).call
    expect(pids).to match_array [participant_id, second_participant_id]
  end
end
