# frozen_string_literal: true

require "rails_helper"

RSpec.describe TranscriptionContractor, type: :model do
  before do
    @transcription_contractor = TranscriptionContractor.new(
      qat_name: "Genesis Government Solutions, Inc.",
      qat_directory: "BVA Hearing Transcripts/Genesis Government Solutions, Inc.",
      qat_poc: "Example POC",
      qat_phone: "888-888-8888",
      qat_email: "test_email@bah.com"
    )
  end

  it "is valid with valid attributes" do
    expect(@transcription_contractor).to be_valid
  end

  it "is not valid without a qat_name" do
    @transcription_contractor.qat_name = nil
    expect(@transcription_contractor).not_to be_valid
  end

  it "is not valid without a qat_directory" do
    @transcription_contractor.qat_directory = nil
    expect(@transcription_contractor).not_to be_valid
  end

  it "has correct default values" do
    expect(@transcription_contractor.qat_stop).to eq(false)
    expect(@transcription_contractor.previous_goal).to eq(0)
    expect(@transcription_contractor.current_goal).to eq(0)
    expect(@transcription_contractor.inactive).to eq(false)
  end
end
