# frozen_string_literal: true

describe JudgeRepository, :all_dbs do
  let(:staff_count) { 3 }


  before(:all) do
    judges = create_list(:staff, 3, :judge_role)
    acting_judges = create_list(:staff, 3, :attorney_judge_role)
    attorneys = create_list(:staff, 3, :attorney_role)
    misc_staff = create_list(:staff, 3, sactive: "I")

    judges.each_with_index do |s, index|
      s.sdomainid = "JUDGE#{index}"
      s.snamef = "J#{index}"
      s.sattyid = nil if index == 0
    end.map(&:save!)
    acting_judges.each_with_index do |s, index|
      s.sdomainid = "ACTING#{index}"
      s.snamef = "Aj#{index}"
    end.map(&:save!)
    attorneys.each_with_index do |s, index|
      s.sdomainid = "ATTY#{index}"
      s.snamef = "A#{index}"
    end.map(&:save!)
    misc_staff.each_with_index do |s, index|
      s.sdomainid = "MISC#{index}"
      s.snamef = "M#{index}"
    end.map(&:save!)
  end

  context ".find_all_having_attorney_ids" do
    subject { AttorneyRepository.find_all_having_attorney_ids }

    it "should return only active attorneys, judges, and acting judges" do
      expect(subject.pluck(:css_id)).to include("ATTY0", "ATTY1", "ATTY2", "ACTING0", "ACTING1", "ACTING2",
                                                "JUDGE1", "JUDGE2")
      expect(subject.pluck(:css_id)).not_to include("JUDGE0", "MISC0", "MISC1", "MISC2")
    end
  end

  context ".find_all_having_attorney_ids_excluding_judges" do
    subject { AttorneyRepository.find_all_having_attorney_ids_excluding_judges }

    it "should return only active attorneys and acting judges" do
      expect(subject.pluck(:css_id)).to include("ATTY0", "ATTY1", "ATTY2", "ACTING0", "ACTING1", "ACTING2")
      expect(subject.pluck(:css_id)).not_to include("JUDGE0", "JUDGE1", "JUDGE2", "MISC0", "MISC1", "MISC2")
    end
  end
end
