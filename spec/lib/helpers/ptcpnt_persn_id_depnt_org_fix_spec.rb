
require "helpers/ptcpnt_persn_id_depnt_org_fix"

describe PtcpntPersnIdDepntOrgFix, :postgres do
  let(:error_text) { "participantPersonId does not match a dependent or an organization" }
  let(:veteran_file_number) { "123456789" }
  let(:correct_pid) { "654321" }
  let(:incorrect_pid) { "incorrect_pid" }
  let(:end_product_establishment) { create(:end_product_establishment, claimant_participant_id: incorrect_pid) }
  let(:claimant) do
    create(
      :claimant,
      participant_id: incorrect_pid,
      type: "VeteranClaimant", payee_code: "00"
    )
  end
  # let!(:incorrect_person_record) do
  #   create(
  #     participant_id: "incorrect_pid",
  #     claimants: [
  #       claimant
  #     ]
  #   )
  # end
  # let(:incorrect_person) { create(:person, participant_id: "incorrect_pid") }
  let(:correct_person) { create(:person, participant_id: correct_pid, ssn: veteran_file_number) }
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
  let!(:stuck_job_report_service) { StuckJobReportService.new }

  subject { described_class.new(stuck_job_report_service) }

  describe "BGS Service Call" do
    context "BGS Service fails" do
      before do
        # Stub BGSService to simulate an error response
        allow_any_instance_of(BGSService).to receive(:fetch_veteran_info).with(veteran_file_number) do
          fail StandardError, "Simulated BGS error"
        end
      end
      it "handles errors from BGSService and logs errors appropriately" do
        # Ensure that log_error is being called
        expect(subject).to receive(:log_error).with(StandardError).at_least(:once)
        subject.retrieve_correct_pid(veteran_file_number)
      end

      it "logs to the stuck_job_report_service" do
        expect(subject.instance_variable_get(:@stuck_job_report_service).logs).to receive(:push).with(/Error retrieving participant ID for veteran file number #{veteran_file_number}: Simulated BGS error/).at_least(:once)
        subject.retrieve_correct_pid(veteran_file_number)
      end
    end

    context "BGS Service succeeds" do
      before do
        # Stub BGSService to simulate an error response
        allow_any_instance_of(BGSService).to receive(:fetch_veteran_info) do
          { ptcpnt_id: correct_pid }
        end
      end
      it "sends back the correct_pid" do
        subject.start_processing_records
      end
    end
  end

  describe "Association Processing" do
    before do
      # Stub BGSService to simulate an error response
      allow_any_instance_of(BGSService).to receive(:fetch_veteran_info) do
        { ptcpnt_id: correct_pid }
      end
    end

    context "BgsPowerOfAttorney record" do
      let!(:bgs_power_of_attorney) { create(:bgs_power_of_attorney, claimant_participant_id: "incorrect_pid") }

      it "correctly identifies and processes records with incorrect participant_id for BgsPowerOfAttorney" do
        subject.start_processing_records
        expect(bgs_power_of_attorney.reload.claimant_participant_id).to eq(correct_pid)
      end
    end

    describe '#handle_person_and_claimant_records' do
      it 'handles person records' do
        correct_person
        expect {
          subject.handle_person_and_claimant_records(correct_pid, supplemental_claim)
        }.to change { Person.count }.by(-1) # Expect one person to be destroyed
      end

      it 'updates supplemental_claim to the correct claimant' do
        correct_person
        subject.handle_person_and_claimant_records(correct_pid, supplemental_claim)
        supplemental_claim.reload
        expect(supplemental_claim.claimant.participant_id).to eq(correct_pid)
      end

      it 'updates supplemental_claim to the correct person' do
        correct_person
        subject.handle_person_and_claimant_records(correct_pid, supplemental_claim)
        supplemental_claim.reload
        expect(supplemental_claim.claimant.person.participant_id).to eq(correct_pid)
      end

      it 'handles person and claimant records when correct person not found' do
        allow(subject).to receive(:get_correct_person).with(correct_pid).and_return(nil)
          expect {
            subject.handle_person_and_claimant_records(correct_pid, supplemental_claim)
          }.not_to change { Person.count } # Expect no person to be destroyed
      end



    end

    # context "Claimant record" do
    #   context "On PID and payee_code" do
    #     it "correctly updates participant ID" do
    #       binding.pry
    #       subject.start_processing_records
    #       binding.pry
    #       expect(claimant.reload.participant_id).to eq(correct_pid)
    #     end

    #     it "correctly updates payee_code" do
    #       claimant.update(payee_code: nil)
    #       subject.start_processing_records
    #       expect(claimant.reload.payee_code).to eq("00")
    #     end
    #   end
    # end

    # context "Person record" do
    #   context "Correct Person exists" do
    #     it "detroys the incorrect Person record" do
    #       # binding.pry
    #       subject.start_processing_records
    #       # expect { incorrect_person_record.destroy! }.to change { Person.count }.by(-1)
    #     end
    #   end
    # end

    # Add more examples for other associations
  end
end
