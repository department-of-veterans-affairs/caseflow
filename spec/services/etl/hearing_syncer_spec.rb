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

    context "orphaned Hearing" do
      let!(:orphaned_hearing) { create(:hearing) }
      let(:etl_build_table) { ETL::BuildTable.where(table_name: "hearings").last }

      before do
        orphaned_hearing.appeal.delete # not destroy, to avoid callbacks
      end

      it "skips orphans" do
        subject

        expect(Hearing.count).to eq(3)
        expect(ETL::Hearing.count).to eq(2)
        expect(etl_build_table).to be_complete
        expect(etl_build_table.rows_rejected).to eq(1)
        expect(etl_build_table.rows_inserted).to eq(2)
        expect(etl_build_table.rows_updated).to eq(0)
      end
    end
  end
end
