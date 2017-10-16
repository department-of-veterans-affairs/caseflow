RSpec.describe MasterRecordHelper, type: :helper do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  context ".remove_master_records_with_children" do
    subject { MasterRecordHelper.remove_master_records_with_children(records) }

    context "when master records have children" do
      let(:video_parent1) { OpenStruct.new(master_record_type: :video, hearing_pkseq: 1234) }
      let(:video_parent2) { OpenStruct.new(master_record_type: :video, hearing_pkseq: 5678) }
      let(:video_child1) { OpenStruct.new(hearing_pkseq: 9999, vdkey: "1234") }
      let(:video_child2) { OpenStruct.new(hearing_pkseq: 8888, vdkey: "1234") }
      let(:co_child1) { OpenStruct.new(hearing_pkseq: 7777) }
      let(:tb_parent1) { OpenStruct.new(master_record_type: :travel_board, tbsched_vdkey: "2012-26-1") }
      let(:tb_parent2) { OpenStruct.new(master_record_type: :travel_board, tbsched_vdkey: "2013-12-1") }
      let(:tb_child2) { OpenStruct.new(hearing_pkseq: 6666, vdkey: "2013-12-1") }

      let(:records) do
        [video_parent1, video_parent2, video_child1, video_child2, co_child1, tb_parent1, tb_parent2, tb_child2]
      end

      it "should remove master records with children" do
        # 2 master records with children
        expect(subject.size).to eq 6
        # video_parent1 and tb_parent2 have children
        expect(subject).to_not include video_parent1
        expect(subject).to_not include tb_parent2
      end
    end
  end

  context ".values_based_on_type" do
    subject { MasterRecordHelper.values_based_on_type(vacols_record) }

    context "when a hearing is a video master record" do
      let(:vacols_record) do
        OpenStruct.new(
          folder_nr: "VIDEO RO15",
          hearing_date: Time.zone.now,
          master_record_type: :video
        )
      end
      it { is_expected.to eq(type: :video, ro: "RO15", dates: [Time.zone.now]) }
    end

    context "when a hearing is a travel board master record" do
      let(:vacols_record) do
        OpenStruct.new(
          tbro: "RO19",
          tbstdate: Time.zone.now,
          tbenddate: Time.zone.now + 3.days,
          master_record_type: :travel_board
        )
      end
      it do
        is_expected.to eq(type: :travel,
                          ro: "RO19",
                          dates: [Time.zone.now, Time.zone.now + 1.day,
                                  Time.zone.now + 2.days, Time.zone.now + 3.days])
      end
    end

    context "when a hearing is not a master record" do
      let(:vacols_record) do
        OpenStruct.new(
          hearing_type: "T",
          master_record_type: nil,
          bfregoff: "RO36"
        )
      end
      it { is_expected.to eq(nil) }
    end
  end
end
