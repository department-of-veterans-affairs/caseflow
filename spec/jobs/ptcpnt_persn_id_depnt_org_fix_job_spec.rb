# frozen_string_literal: true

describe PtcpntPersnIdDepntOrgFixJob, :postgres do
  let(:error_text) { "participantPersonId does not match a dependent or an organization" }
  let(:veteran_file_number) {"123456789"}
  let(:correct_pid) {"654321"}
  let(:end_product_establishment) { create(:end_product_establishment, claimant_participant_id: "incorrect_pid") }
  let(:claimant) { create(:claimant, participant_id: "incorrect_pid", type: "VeteranClaimant", payee_code: "00") }
  let!(:supplemental_claim) do
    create(
      :supplemental_claim,
      establishment_error: error_text,
      claimants: [
        claimant
      ],
      end_product_establishments: [
        end_product_establishment
      ]
    )
  end

  it_behaves_like "a Master Scheduler serializable object", PtcpntPersnIdDepntOrgFixJob

  subject { described_class.new }


  # context "BGS Service fails" do
  #   before do
  #     # Stub BGSService to simulate an error response
  #     allow_any_instance_of(BGSService).to receive(:fetch_veteran_info).with(veteran_file_number) do
  #       raise StandardError, "Simulated BGS error"
  #     end
  #   end
  #   it "handles errors from BGSService and logs errors appropriately" do
  #     # Ensure that log_error is being called
  #     expect(subject).to receive(:log_error).with("Error retrieving participant ID for veteran file number #{veteran_file_number}: Simulated BGS error").at_least(:once)
  #   end

  #   it "logs to the stuck_job_report_service" do
  #     expect { subject.retrieve_correct_pid(veteran_file_number) }.to change { subject.instance_variable_get(:@stuck_job_report_service).logs.count }.by(1)
  #   end
  # end

  # context "BGS Service succeeds" do
  #   before do
  #     # Stub BGSService to simulate an error response
  #     allow_any_instance_of(BGSService).to receive(:fetch_veteran_info) do
  #       { ptcpnt_id: correct_pid }
  #     end
  #   end
  #   it "sends back the correct_pid" do
  #     subject.perform
  #   end

  # end

  # describe "association processing" do
  #   # Use factories or create test data as needed for each association
  #   let!(:bgs_power_of_attorney) { create(:bgs_power_of_attorney, claimant_participant_id: "incorrect_pid") }
  #   # Add more associations as needed

  #   it "correctly identifies and processes records with incorrect participant_id for BgsPowerOfAttorney" do
  #     # expect(subject).to receive(:process_records).with(correct_pid, "incorrect_pid").once
  #     binding.pry
  #     subject.perform
  #     # binding.pry
  #     expect(bgs_power_of_attorney.reload.claimant_participant_id).to eq(correct_pid)
  #   end

  #   it "correctly identifies and processes records with incorrect participant_id for Claimant" do
  #     expect(subject).to receive(:process_records).with(correct_pid, "incorrect_pid").once
  #     subject.perform
  #     expect(claimant.reload.participant_id).to eq(correct_pid)
  #   end

  #   # Add more examples for other associations
  # end

end


