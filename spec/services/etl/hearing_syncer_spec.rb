# frozen_string_literal: true

describe ETL::HearingSyncer, :etl, :all_dbs do
  let(:etl_build) { ETL::Build.create }
  let!(:virtual_hearing) { create(:virtual_hearing, hearing: video_hearing) }
  let(:video_hearing) do
    build(:hearing, :with_tasks, hearing_day: hearing_day)
  end
  let(:hearing_day) do
    create(:hearing_day, regional_office: "RO89", request_type: HearingDay::REQUEST_TYPES[:video])
  end

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    context "virtual hearing" do
      it "syncs" do
        subject

        expect(Hearing.count).to eq(1)
        expect(ETL::Hearing.count).to eq(1)
        expect(ETL::Hearing.first.hearing_request_type).to eq "Virtual"
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

        expect(Hearing.count).to eq(2)
        expect(ETL::Hearing.count).to eq(1)
        expect(etl_build_table).to be_complete
        expect(etl_build_table.rows_rejected).to eq(1)
        expect(etl_build_table.rows_inserted).to eq(1)
        expect(etl_build_table.rows_updated).to eq(0)
      end
    end
  end
end
