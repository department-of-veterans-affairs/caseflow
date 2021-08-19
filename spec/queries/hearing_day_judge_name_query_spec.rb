# frozen_string_literal: true

describe HearingDayJudgeNameQuery do
  subject do
    HearingDayJudgeNameQuery.new(
      HearingDay.where(id: [hearing_day_one.id, hearing_day_two.id])
    ).call
  end

  context "hearings days" do
    let(:judge_one) { create(:user, :with_vacols_judge_record, full_name: "Richard Sanchez") }
    let(:judge_two) { create(:user, :with_vacols_judge_record, full_name: "Mortimer Smith") }
    let(:hearing_day_one) { create(:hearing_day, judge_id: judge_one.id) }
    let(:hearing_day_two) { create(:hearing_day, judge_id: judge_two.id) }

    it "returns correct values from CachedUsers table and not Users table" do
      vacols_staff_one = VACOLS::Staff.find_by(sdomainid: judge_one.css_id)
      vacols_staff_two = VACOLS::Staff.find_by(sdomainid: judge_two.css_id)
      vacols_staff_one.update(snamef: "Ricky")
      vacols_staff_two.update(snamef: "Morty")

      CachedUser.sync_from_vacols

      expect(subject.fetch(hearing_day_one.id).fetch(:first_name)).to eq(judge_one.vacols_user.snamef)
      expect(subject.fetch(hearing_day_one.id).fetch(:last_name)).to eq(judge_one.vacols_user.snamel)
      expect(subject.fetch(hearing_day_two.id).fetch(:first_name)).to eq(judge_two.vacols_user.snamef)
      expect(subject.fetch(hearing_day_two.id).fetch(:last_name)).to eq(judge_two.vacols_user.snamel)
    end
  end
end
