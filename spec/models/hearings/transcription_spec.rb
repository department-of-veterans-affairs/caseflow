# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transcription, type: :model do
  let!(:transcription_contractor) { create(:transcription_contractor) }
  let!(:transcription_1) { create(:transcription, transcription_contractor_id: transcription_contractor.id) }
  let!(:transcription_2) { create(:transcription) }

  it "can belong to a transcription contractor" do
    expect(transcription_1.transcription_contractor).to eq(transcription_contractor)
  end

  it "can have no transcription contractor" do
    expect(transcription_2.transcription_contractor).to be_nil
  end
end
