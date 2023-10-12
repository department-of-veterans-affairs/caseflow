# frozen_string_literal: true

describe VACOLS::CaseHearing, :all_dbs do
  specify "primary key sequence increments in intervals of 1" do
    case_hearing_1 = create(:case_hearing)
    case_hearing_2 = create(:case_hearing)
    expect(case_hearing_2.hearing_pkseq - case_hearing_1.hearing_pkseq).to eq(1)
  end

  context ".load_hearing" do
    subject { VACOLS::CaseHearing.load_hearing(case_hearing.hearing_pkseq).hearing_venue }
    let(:ro_id) { "RO04" }
    let!(:legacy_appeal) do
      create(:legacy_appeal, vacols_case: vacols_case, closest_regional_office: ro_id)
    end
    let!(:vacols_case) do
      create(
        :case,
        bfregoff: ro_id,
        bfdocind: HearingDay::REQUEST_TYPES[:video]
      )
    end
    context "after 2019-03-29" do
      let!(:case_hearing) do
        create(
          :case_hearing,
          hearing_type: HearingDay::REQUEST_TYPES[:central],
          folder_nr: legacy_appeal.vacols_id
        )
      end
      it "sets hearing_venue to bfregoff value" do
        expect(subject).to eq(ro_id)
      end
    end
    context "not video and before 2019-03-29" do
      let!(:case_hearing) do
        create(
          :case_hearing,
          hearing_type: HearingDay::REQUEST_TYPES[:central],
          hearing_date: "2019-03-28",
          folder_nr: legacy_appeal.vacols_id
        )
      end
      it "sets hearing_venue to bfregoff value" do
        expect(subject).to eq(ro_id)
      end
    end
    context "before 2019-03-29 and video hearing" do
      let!(:case_hearing) do
        create(
          :case_hearing,
          hearing_type: HearingDay::REQUEST_TYPES[:video],
          hearing_date: "2019-03-28",
          folder_nr: legacy_appeal.vacols_id
        )
      end
      it "sets hearing to the result of HEARING_VENUE function which is NOT bfregoff field" do
        expect(subject).to_not eq(ro_id)
      end
    end
  end
end
