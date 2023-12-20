# frozen_string_literal: true

describe HearingDayJudgeNameQuery do
  subject do
    HearingDayJudgeNameQuery.new(hearing_days)
  end

  context "hearings days" do
    let(:user_one_first_name) { "Richard" }
    let(:user_one_last_name) { "Sanchez" }
    let(:user_one_full_name) { "#{user_one_first_name} #{user_one_last_name}" }
    let(:judge_one) { create(:user, :with_vacols_judge_record, full_name: user_one_full_name) }

    let(:user_two_first_name) { "Mortimer" }
    let(:user_two_last_name) { "Smith" }
    let(:user_two_full_name) { "#{user_two_first_name} #{user_two_last_name}" }
    let(:judge_two) { create(:user, :with_vacols_judge_record, full_name: user_two_full_name) }

    let(:staff_one_first_name) { "Ricky" }
    let(:staff_two_first_name) { "Morty" }

    let!(:hearing_day_one) { create(:hearing_day, judge: judge_one) }
    let!(:hearing_day_two) { create(:hearing_day, judge: judge_two) }

    shared_examples "returns_correct_values" do
      it "returns correct values from CachedUsers table and not Users table" do
        CachedUser.sync_from_vacols

        values = subject.call
        expect(values.fetch(hearing_day_one.id).fetch(:first_name)).to eq(user_one_first_name)
        expect(values.fetch(hearing_day_one.id).fetch(:last_name)).to eq(user_one_last_name)
        expect(values.fetch(hearing_day_two.id).fetch(:first_name)).to eq(user_two_first_name)
        expect(values.fetch(hearing_day_two.id).fetch(:last_name)).to eq(user_two_last_name)

        vacols_staff_one = VACOLS::Staff.find_by(sdomainid: judge_one.css_id)
        vacols_staff_two = VACOLS::Staff.find_by(sdomainid: judge_two.css_id)
        vacols_staff_one.update(snamef: staff_one_first_name)
        vacols_staff_two.update(snamef: staff_two_first_name)

        CachedUser.sync_from_vacols

        values = subject.call
        expect(values.fetch(hearing_day_one.id).fetch(:first_name)).to eq(staff_one_first_name)
        expect(values.fetch(hearing_day_one.id).fetch(:last_name)).to eq(user_one_last_name)
        expect(values.fetch(hearing_day_two.id).fetch(:first_name)).to eq(staff_two_first_name)
        expect(values.fetch(hearing_day_two.id).fetch(:last_name)).to eq(user_two_last_name)
      end
    end

    context "passing HearingDays as ActiveRecord::Relation" do
      let(:hearing_days) { HearingDay.where(id: [hearing_day_one.id, hearing_day_two.id]) }

      include_examples "returns_correct_values"
    end

    context "passing HearingDays as Array" do
      let(:hearing_days) { [hearing_day_one.id, hearing_day_two.id].map { |id| HearingDay.find(id) } }

      include_examples "returns_correct_values"
    end

    context "passing empty value" do
      let(:hearing_days) { [] }

      it "returns an empty object" do
        values = subject.call
        expect(values).to eq({})
      end
    end
  end
end
