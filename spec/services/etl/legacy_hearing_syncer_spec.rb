# frozen_string_literal: true

describe ETL::LegacyHearingSyncer, :etl, :all_dbs do
  let(:etl_build) { ETL::Build.create }
  let(:regional_office) { "RO89" }
  let!(:virtual_hearing) { create(:virtual_hearing, hearing: video_hearing) }
  let(:video_hearing) do
    create(:legacy_hearing, hearing_day: hearing_day, regional_office: regional_office)
  end
  let(:hearing_day) do
    create(
      :hearing_day,
      scheduled_for: scheduled_for,
      regional_office: regional_office,
      request_type: HearingDay::REQUEST_TYPES[:video]
    )
  end
  let!(:regional_hearing) do
    create(:legacy_hearing, hearing_day: hearing_day)
  end
  let(:scheduled_for) do
    Time.use_zone("America/New_York") { Time.zone.local(2018, 1, 1, 0, 0, 0) }
  end

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    context "virtual hearing" do
      it "syncs" do
        subject

        expect(LegacyHearing.count).to eq(2)
        expect(ETL::LegacyHearing.count).to eq(2)
        etl_virtual_hearing = ETL::LegacyHearing.find_by(hearing_id: virtual_hearing.hearing_id)
        etl_regional_hearing = ETL::LegacyHearing.find_by(hearing_id: regional_hearing.id)
        expect(etl_virtual_hearing.hearing_request_type).to eq "Virtual"
        expect(etl_virtual_hearing.hearing_location_zip_code).to eq "20001"
        expect(etl_regional_hearing.hearing_request_type).to eq "Video"
        expect(etl_regional_hearing.hearing_location_zip_code).to be_nil
      end
    end

    context "VACOLS hearing not found" do
      before do
        create(:legacy_hearing, vacols_id: "no-such-vacols-record")
        allow(Rails.logger).to receive(:error).and_call_original
      end

      it "rescues Caseflow::Error::VacolsRecordNotFound and continues" do
        subject

        expect(LegacyHearing.count).to eq(3)
        expect(ETL::LegacyHearing.count).to eq(2)
        expect(Rails.logger).to have_received(:error).once
        expect(etl_build.reload.build_for("hearings").rows_rejected).to eq(1)
      end
    end

    context "orphaned Hearing" do
      let!(:orphaned_hearing) { create(:legacy_hearing) }
      let(:etl_build_table) { ETL::BuildTable.where(table_name: "hearings").last }

      before do
        orphaned_hearing.appeal.delete # not destroy, to avoid callbacks
      end

      it "skips orphans" do
        subject

        expect(LegacyHearing.count).to eq(3)
        expect(ETL::LegacyHearing.count).to eq(2)
        expect(etl_build_table).to be_complete
        expect(etl_build_table.rows_rejected).to eq(1)
        expect(etl_build_table.rows_inserted).to eq(2)
        expect(etl_build_table.rows_updated).to eq(0)
      end
    end

    context "with disposition" do
      let(:video_hearing) do
        create(
          :legacy_hearing,
          hearing_day: hearing_day,
          regional_office: regional_office,
          disposition: :H
        )
      end

      it "syncs" do
        subject

        expect(LegacyHearing.count).to eq(2)
        expect(ETL::LegacyHearing.count).to eq(2)
        etl_virtual_hearing = ETL::LegacyHearing.find_by(hearing_id: virtual_hearing.hearing_id)
        etl_regional_hearing = ETL::LegacyHearing.find_by(hearing_id: regional_hearing.id)
        expect(etl_virtual_hearing.disposition).to eq Constants.HEARING_DISPOSITION_TYPES.held
        expect(etl_regional_hearing.disposition).to be_nil
      end
    end
  end
end
