# frozen_string_literal: true

describe ETL::HearingSyncer, :etl, :all_dbs do
  let(:etl_build) { ETL::Build.create }
  let(:regional_office) { "RO89" }
  let!(:virtual_hearing) { create(:virtual_hearing, hearing: video_hearing) }
  let(:video_hearing) do
    build(:hearing, :with_tasks, hearing_day: hearing_day, regional_office: regional_office)
  end
  let(:hearing_day) do
    create(:hearing_day, regional_office: regional_office, request_type: HearingDay::REQUEST_TYPES[:video])
  end
  let!(:regional_hearing) do
    create(:hearing, :with_tasks, hearing_day: hearing_day)
  end

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    context "virtual hearing" do
      it "syncs" do
        subject

        expect(Hearing.count).to eq(2)
        expect(ETL::Hearing.count).to eq(2)
        etl_virtual_hearing = ETL::Hearing.find_by(hearing_id: virtual_hearing.hearing_id)
        etl_regional_hearing = ETL::Hearing.find_by(hearing_id: regional_hearing.id)
        expect(etl_virtual_hearing.hearing_request_type).to eq "Virtual"
        expect(etl_virtual_hearing.hearing_location_zip_code).to eq "20001"
        expect(etl_regional_hearing.hearing_request_type).to eq "Video"
        expect(etl_regional_hearing.hearing_location_zip_code).to be_nil
      end
    end
  end
end
