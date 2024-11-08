# frozen_string_literal: true

describe CheckVeteranResidenceLocationJob, :all_dbs do
  subject { described_class.perform_now }

  context "job run" do
    let(:vet_file_number) { "123456788" }
    let(:vet_ssn) { "666660000" }
    let!(:veteran) { create(:veteran, file_number: vet_file_number, ssn: vet_ssn) }

    before do
      attrs = {
        file_number: vet_file_number,
        first_name: "Veteran",
        last_name: "ResidenceTest",
        ssn: vet_ssn,
        state: "FL",
        country: "US"
      }

      Generators::Veteran.build(attrs)
    end

    it "updates the veteran residence location", bypass_cleaner: true do
      vet_before_job_run = Veteran.find_by_file_number_or_ssn(vet_file_number)
      expect(vet_before_job_run).to_not be_nil

      subject

      vet_after_job_run = Veteran.find_by_file_number_or_ssn(vet_file_number)

      expect(vet_before_job_run.state_of_residence).not_to eq vet_after_job_run.state_of_residence
      expect(vet_before_job_run.country_of_residence).not_to eq vet_after_job_run.country_of_residence
      expect(vet_after_job_run.state_of_residence).to eq "FL"
      expect(vet_after_job_run.country_of_residence).to eq "US"
    end

    it "catches standard errors outside of parallel threads", bypass_cleaner: true do
      allow(Veteran).to receive(:where).and_raise(StandardError, "Connection Error")

      expect_any_instance_of(CheckVeteranResidenceLocationJob).to receive(:log_error).once

      subject
    end

    it "catches standard errors within the parallel threads", bypass_cleaner: true do
      allow_any_instance_of(Veteran).to receive(:address).and_raise(BGS::ShareError, "Error")

      expect_any_instance_of(CheckVeteranResidenceLocationJob).to receive(:log_error).once

      subject
    end

    # Clean up parallel threads
    after(:each) { clean_up_after_threads }

    def clean_up_after_threads
      DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
    end
  end
end
