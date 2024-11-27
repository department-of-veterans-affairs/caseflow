# frozen_string_literal: true

require "rails_helper"

RSpec.describe TranscriptionContractor, type: :model do
  let!(:transcription_contractor_1) { create(:transcription_contractor, name: "The Ravens Group, Inc.") }
  let!(:transcription_contractor_2) { create(:transcription_contractor, name: "Genesis Government Solutions, Inc.") }
  let!(:transcription_contractor_3) { create(:transcription_contractor, name: "Vet Reporting") }
  let!(:transcription_1) { create(:transcription, transcription_contractor_id: transcription_contractor_1.id) }
  let!(:transcription_2) { create(:transcription, transcription_contractor_id: transcription_contractor_1.id) }

  it { is_expected.to validate_presence_of :current_goal }
  it { is_expected.to validate_presence_of :directory }
  it { is_expected.to validate_presence_of :email }
  it { should allow_value([true, false]).for(:inactive) }
  it { should allow_value([true, false]).for(:is_available_for_work) }
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :phone }
  it { is_expected.to validate_presence_of :poc }

  it "can have many transcriptions" do
    expect(transcription_contractor_1.transcriptions).to eq([transcription_1, transcription_2])
  end

  describe ".all_contractors" do
    it "returns all contractors ordered alphabetically" do
      expect(described_class.all_contractors).to eq(
        [transcription_contractor_2, transcription_contractor_1, transcription_contractor_3]
      )
    end
  end

  describe "#assign_previous_goal" do
    it "current goal is set to previous goal before current goal is saved" do
      transcription_contractor_1.update!(current_goal: 1)
      expect(transcription_contractor_1.current_goal).to eq 1
      expect(transcription_contractor_1.previous_goal).to eq 0
      transcription_contractor_1.update!(current_goal: 2)
      expect(transcription_contractor_1.current_goal).to eq 2
      expect(transcription_contractor_1.previous_goal).to eq 1
    end
  end
end
