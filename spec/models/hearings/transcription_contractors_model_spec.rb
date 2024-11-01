# frozen_string_literal: true

require "rails_helper"

RSpec.describe TranscriptionContractor, type: :model do
  before do
    @transcription_contractor = TranscriptionContractor.new(
      name: "Genesis Government Solutions, Inc.",
      directory: "BVA Hearing Transcripts/Genesis Government Solutions, Inc.",
      poc: "Example POC",
      phone: "888-888-8888",
      email: "test_email@bah.com"
    )
  end

  it "is valid with valid attributes" do
    expect(@transcription_contractor).to be_valid
  end

  it "is not valid without a name" do
    @transcription_contractor.name = nil
    expect(@transcription_contractor).not_to be_valid
  end

  it "is not valid without a directory" do
    @transcription_contractor.directory = nil
    expect(@transcription_contractor).not_to be_valid
  end

  it "has correct default values" do
    expect(@transcription_contractor.is_available_for_work).to eq(false)
    expect(@transcription_contractor.previous_goal).to eq(0)
    expect(@transcription_contractor.current_goal).to eq(0)
    expect(@transcription_contractor.inactive).to eq(false)
  end
end
