# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hearings::UpdateTranscriptionPackageStatusJob, type: :job do
  let!(:assigned_package) do
    create(
      :transcription_package,
      status: "Sent",
      expected_return_date: Time.zone.now + 7.days
    )
  end
  let!(:completed_package) { create(:transcription_package, status: "Completed", returned_at: Time.zone.now + 7.days) }
  let!(:failed_retrieval_package) { create(:transcription_package, status: "Failed Retrieval (BOX)") }

  describe "#perform" do
    it 'updates overdue assigned packages to "Overdue"' do
      described_class.perform_now
      expect(assigned_package.reload.status).to eq("Overdue")
    end
    it 'updates overdue completed packages to "Overdue"' do
      described_class.perform_now
      expect(completed_package.reload.status).to eq("Overdue")
    end
    it 'updates failed retrieval packages to "Retrieval failure"' do
      described_class.perform_now
      expect(failed_retrieval_package.reload.status).to eq("Retrieval Failure")
    end
  end
end
