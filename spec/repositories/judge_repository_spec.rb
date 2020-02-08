# frozen_string_literal: true

describe JudgeRepository, :all_dbs do
  let(:staff_count) { 3 }

  let!(:judges) { create_list(:staff, staff_count, :judge_role) }
  let!(:acting_judges) { create_list(:staff, staff_count, :attorney_judge_role) }
  let!(:attorneys) { create_list(:staff, staff_count, :attorney_role) }

  before do
    judges.each_with_index do |s, index|
      s.sdomainid = "JUDGE#{index}"
      s.snamef = "J#{index}"
    end.map(&:save!)
    acting_judges.each_with_index do |s, index|
      s.sdomainid = "ACTING#{index}"
      s.snamef = "Aj#{index}"
    end.map(&:save!)
    attorneys.each_with_index do |s, index|
      s.sdomainid = "ATTY#{index}"
      s.snamef = "A#{index}"
    end.map(&:save!)
  end

  context ".find_all_judges" do
    subject { JudgeRepository.find_all_judges }

    it "should return only judges and acting judges" do
      expect(subject.pluck(:css_id)).to include("ACTING0", "ACTING1", "ACTING2", "JUDGE0", "JUDGE1", "JUDGE2")
      expect(subject.pluck(:css_id)).not_to include("ATTY0", "ATTY1", "ATTY2")
    end
  end

  context ".find_all_judges_with_name_and_id" do
    subject { JudgeRepository.find_all_judges_with_name_and_id }

    it "should return names of only judges and acting judges" do
      expect(subject.pluck(:first_name)).to include("J0", "J1", "J2", "Aj0", "Aj1", "Aj2")
      expect(subject.pluck(:first_name)).not_to include("A0", "A1", "A2")
    end
  end
end
