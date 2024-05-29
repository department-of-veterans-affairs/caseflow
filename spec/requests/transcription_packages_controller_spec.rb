# frozen_string_literal: true

RSpec.describe "the Hearings::TranscriptionPackagesController", type: :request do
  describe "the show response" do
    let(:hearings) { (1..5).map { create(:hearing, :with_transcription_files) } }
    let(:legacy_hearings) { (1..5).map { create(:legacy_hearing, :with_transcription_files) } }
    let(:transcription_package) { create(:transcription_package) }

    before do
      User.authenticate!
      Seeds::TranscriptionContractor.new.seed!
      hearings.each do |hearing|
        ::TranscriptionPackageHearing.create!(
          hearing_id: hearing.id,
          transcription_package_id: transcription_package.id
        )
      end
      legacy_hearings.each do |legacy_hearing|
        ::TranscriptionPackageLegacyHearing.create!(
          legacy_hearing_id: legacy_hearing.id,
          transcription_package_id: transcription_package.id
        )
      end
      transcription_package.update!(
        contractor_id: TranscriptionContractor.first&.id,
        status: "Successfully uploaded to Box.com"
      )
    end

    it "returns ok status" do
      get hearings_transcription_package_path(transcription_package.task_number)

      expect(response.status).to eq(200)
    end

    it "returns json" do
      get hearings_transcription_package_path(transcription_package.task_number)

      data = JSON.parse(response.body, symbolize_names: true)[:data]

      expect(data.keys).to eq([:id, :type, :attributes])

      attrs = data[:attributes]

      expect(attrs[:taskNumber]).to eq("BVA-1111-0001")
      expect(attrs[:dateSent]).to eq("12/2/2050")
      expect(attrs[:returnDate]).to eq("12/1/2050")
      expect(attrs[:status]).to eq("Successfully uploaded to Box.com")
      expect(attrs[:contractorName]).to eq("Genesis Government Solutions, Inc.")
      expect(attrs[:orderContentsCount]).to eq(10)

      attrs[:hearings].each do |hearing|
        expect(hearing).to be_a(Hash)
        expect(hearing.keys).to eq([:docketNumber, :caseDetails, :hearingType])
      end
    end
  end
end
