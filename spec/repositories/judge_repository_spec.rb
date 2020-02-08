# frozen_string_literal: true

describe JudgeRepository, :all_dbs do
  let(:staff_count) { 3 }

  let!(:judges) { create_list(:staff, staff_count, :judge_role) }
  let!(:acting_judges) { create_list(:staff, staff_count, :attorney_judge_role) }
  let!(:attorneys) { create_list(:staff, staff_count, :attorney_role) }

  context ".find_all_judges" do
    subject { JudgeRepository.find_all_judges }

    it "should return only judges and acting judges" do
      expect(subject.length).to eq(judges.count + acting_judges.count)
    end
  end

  context ".find_all_judges_with_name_and_id" do
    subject { JudgeRepository.find_all_judges_with_name_and_id }
    before do
      judges.each { |s| s.snamef = "Judge J" }.map(&:save!)
      acting_judges.each { |s| s.snamef = "Acting J" }.map(&:save!)
    end

    it "should return only judges and acting judges" do
      expect(subject.length).to eq(judges.count + acting_judges.count)
    end

    it "should return names" do
      expect(subject.map { |s| s[:first_name] }.uniq).to contain_exactly("Judge J", "Acting J")
    end
  end
end
