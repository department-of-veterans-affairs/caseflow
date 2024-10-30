# frozen_string_literal: true

# require "support/shared_context/sync_vet_remediations"

# person_remediation_event_record <-- name this in the file
RSpec.describe Remediations::DuplicatePersonRemediationService do
  include ActiveJob::TestHelper

  # include_context "sync_vet_remediations"

  let(:person_ids) { %w[1234 5678 9101 1213] }

  describe ".initialize" do
    it "exists" do
      expect(person_ids).to be_an(Array)
      expect(person_ids.first).to eq("1234")
      expect(person_ids.first).to be_a(String)
    end
  end

  describe ".remediate" do
    xit "remediates persoupdated ssn numbers" do
      # this test will check the logic to find and delete any duplicate persons
      # will check by ssn
    end
  end
end
