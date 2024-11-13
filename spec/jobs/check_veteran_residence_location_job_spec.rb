# frozen_string_literal: true

describe CheckVeteranResidenceLocationJob, :all_dbs do
  include ActiveJob::TestHelper

  describe "#perform" do
    let!(:vet) { create(:veteran, file_number: "1238", ssn: "1111111113") }

    before do
      vet_attrs = { file_number: vet.file_number, ssn: vet.ssn, state: "FL", country: "US" }

      Generators::Veteran.build(vet_attrs)
    end

    it "updates the veteran residence location", bypass_cleaner: true do
      vet_before_job_run = Veteran.find_by_file_number_or_ssn("1238")
      expect(vet_before_job_run).to_not be_nil

      perform_enqueued_jobs { CheckVeteranResidenceLocationJob.perform_later }

      vet_after_job_run = Veteran.find_by_file_number_or_ssn("1238")

      expect(vet_before_job_run.state_of_residence).not_to eq vet_after_job_run.state_of_residence
      expect(vet_before_job_run.country_of_residence).not_to eq vet_after_job_run.country_of_residence
      expect(vet_after_job_run.state_of_residence).to eq "FL"
      expect(vet_after_job_run.country_of_residence).to eq "US"
    end

    it "catches standard errors within the parallel threads", bypass_cleaner: true do
      allow_any_instance_of(Veteran).to receive(:address).and_raise(BGS::ShareError, "Error")

      expect_any_instance_of(CheckVeteranResidenceLocationJob).to receive(:log_error).once

      perform_enqueued_jobs { CheckVeteranResidenceLocationJob.perform_later }
    end

    # Clean up parallel threads
    after(:each) { clean_up_after_threads }

    def clean_up_after_threads
      DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
    end
  end

  describe "#retrieve_veterans" do
    let!(:veteran1) do
      create(:veteran, file_number: "1234", ssn: "1111111111", state_of_residence: "FL",
                       country_of_residence: "US", residence_location_last_checked_at: Time.zone.now)
    end
    let!(:veteran2) do
      create(:veteran, file_number: "1235", ssn: "1111111112", state_of_residence: "CA",
                       country_of_residence: "US", residence_location_last_checked_at: 2.weeks.ago)
    end
    let!(:veteran3) { create(:veteran, file_number: "1236", ssn: "1111111113") }
    let!(:veteran4) { create(:veteran, file_number: "1237", ssn: "1111111114") }

    before do
      vet1_attrs = { file_number: veteran1.file_number, ssn: veteran1.ssn, state: "FL", country: "US" }
      vet2_attrs = { file_number: veteran2.file_number, ssn: veteran2.ssn, state: "CA", country: "US" }
      vet3_attrs = { file_number: veteran3.file_number, ssn: veteran3.ssn, state: "FL", country: "US" }
      vet4_attrs = { file_number: veteran4.file_number, ssn: veteran4.ssn, state: "TX", country: "US" }

      Generators::Veteran.build(vet1_attrs)
      Generators::Veteran.build(vet2_attrs)
      Generators::Veteran.build(vet3_attrs)
      Generators::Veteran.build(vet4_attrs)
    end

    it "retrieves all veterans matching the criteria" do
      res = CheckVeteranResidenceLocationJob.new

      expect(res.send(:retrieve_veterans).length).to be(3)
    end

    it "raises errors for connection issues" do
      allow(Veteran).to receive(:where).and_raise(StandardError, "Connection Error")

      expect_any_instance_of(CheckVeteranResidenceLocationJob).to receive(:log_error).once

      res = CheckVeteranResidenceLocationJob.new
      res.send(:retrieve_veterans)
    end
  end

  describe "#batch_update_veterans" do
    let!(:veteran3) { create(:veteran, file_number: "1236", ssn: "1111111113") }

    before do
      vet3_attrs = { file_number: veteran3.file_number, ssn: veteran3.ssn, state: "FL", country: "US" }

      Generators::Veteran.build(vet3_attrs)
    end

    it "retrieves all veterans matching the criteria" do
      res = CheckVeteranResidenceLocationJob.new

      vet = Veteran.find_by_file_number_or_ssn("1236")
      vet_updates = [{ id: vet.id, state_of_residence: "AZ", country_of_residence: "US",
                       residence_location_last_checked_at: Time.zone.now }]

      res.send(:batch_update_veterans, vet_updates)

      vet_after_update = Veteran.find_by_file_number_or_ssn("1236")

      expect(vet_after_update.state_of_residence).to eq "AZ"
      expect(vet_after_update.country_of_residence).to eq "US"
    end

    it "raises errors for connection issues" do
      # allow(Veteran).to receive(:update).and_raise(StandardError, "Connection Error")

      expect_any_instance_of(CheckVeteranResidenceLocationJob).to receive(:log_error)

      res = CheckVeteranResidenceLocationJob.new
      res.send(:batch_update_veterans, {})
    end
  end
end
