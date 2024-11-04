# frozen_string_literal: true

# require "support/shared_context/sync_vet_remediations"

# veteran_remediation_event_record <-- name this in the file

RSpec.describe Remediations::VeteranRecordRemediationService do
  include ActiveJob::TestHelper

  # include_context "sync_vet_remediations"

  let(:vet_ids) { %w[1234 5678 9101 1213] }

  describe ".initialize" do
    it "exists" do
      expect(vet_ids).to be_an(Array)
      expect(vet_ids.first).to eq("1234")
      expect(vet_ids.first).to be_a(String)
    end
  end

  describe ".remediate" do
    xit "remediates recoreds for a veterans with updated file numbers" do
      # this test we will check the implemented logic to find and update records associated with veterans
      # that have updated file numbers
      # will check by file number and possibly other
    end
  end

  describe ".fix_vet" do
    xit "fixes file number" do
    end
  end

  describe ".updated_veterans" do
    xit "returns a Veteran object from event record" do
    end
  end

  describe ".update_records!" do
    xit "updates incorrect file number assocations for a Veteran" do
    end
  end
end
