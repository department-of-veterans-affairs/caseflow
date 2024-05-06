# frozen_string_literal: true

require "rails_helper"

RSpec.describe TranscriptionContractor, type: :model do
  subject(:transcription_contractor) do
    described_class.new(
      name: "Genesis Government Solutions, Inc.",
      directory: "BVA Hearing Transcripts/Genesis Government Solutions, Inc.",
      poc: "Example POC",
      phone: "888-888-8888",
      email: "test_email@bah.com"
    )
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:directory) }
  end

  describe "default values" do
    it "has correct default values" do
      expect(transcription_contractor.is_available_for_work).to eq(false)
      expect(transcription_contractor.previous_goal).to eq(0)
      expect(transcription_contractor.current_goal).to eq(0)
      expect(transcription_contractor.inactive).to eq(false)
    end
  end

  describe ".all_contractors" do
    let!(:contractors) do
      [
        { name: "Genesis Government Solutions, Inc.",
          directory: "BVA Hearing Transcripts/Genesis Government Solutions, Inc.",
          email: "email_1@test.com",
          phone: "888-888-8888",
          poc: "Example POC" },
        { name: "Jamison Professional Services",
          directory: "BVA Hearing Transcripts/Jamison Professional Services",
          email: "email_2@test.com",
          phone: "888-888-8888",
          poc: "Example POC" },
        { name: "The Ravens Group, Inc.",
          directory: "BVA Hearing Transcripts/The Ravens Group, Inc.",
          email: "email_3@test.com",
          phone: "888-888-8888",
          poc: "Example POC" }
      ].map { |attrs| described_class.create!(attrs) }
    end

    it "returns all contractors" do
      expect(described_class.all_contractors).to contain_exactly(*contractors)
    end
  end
end
