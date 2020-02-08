# frozen_string_literal: true

describe AttorneyRepository, :all_dbs do
  before(:all) do
    judges = create_list(:staff, 3, :judge_role)
    acting_judges = create_list(:staff, 3, :attorney_judge_role)
    attorneys = create_list(:staff, 3, :attorney_role)
    misc_staff = create_list(:staff, 3, sactive: "I")

    judges.each_with_index do |s, index|
      s.sdomainid = "JUDGE#{index}AR"
      s.snamef = "J#{index}"
      s.sattyid = nil if index == 0
    end.map(&:save!)
    acting_judges.each_with_index do |s, index|
      s.sdomainid = "ACTING#{index}AR"
      s.snamef = "Aj#{index}"
    end.map(&:save!)
    attorneys.each_with_index do |s, index|
      s.sdomainid = "ATTY#{index}AR"
      s.snamef = "A#{index}"
    end.map(&:save!)
    misc_staff.each_with_index do |s, index|
      s.sdomainid = "MISC#{index}AR"
      s.snamef = "M#{index}"
    end.map(&:save!)
  end

  context ".find_all_having_attorney_ids" do
    subject { AttorneyRepository.find_all_having_attorney_ids }

    it "should return only active attorneys, judges, and acting judges" do
      expect(subject.pluck(:css_id)).to include("ATTY0AR", "ATTY1AR", "ATTY2AR",
                                                "ACTING0AR", "ACTING1AR", "ACTING2AR",
                                                "JUDGE1AR", "JUDGE2AR")
      expect(subject.pluck(:css_id)).not_to include("JUDGE0AR", "MISC0AR", "MISC1AR", "MISC2AR")
    end
  end

  context ".find_all_having_attorney_ids_excluding_judges" do
    subject { AttorneyRepository.find_all_having_attorney_ids_excluding_judges }

    it "should return only active attorneys and acting judges" do
      expect(subject.pluck(:css_id)).to include("ATTY0AR", "ATTY1AR", "ATTY2AR",
                                                "ACTING0AR", "ACTING1AR", "ACTING2AR")
      expect(subject.pluck(:css_id)).not_to include("JUDGE0AR", "JUDGE1AR", "JUDGE2AR",
                                                    "MISC0AR", "MISC1AR", "MISC2AR")
    end
  end
end
