# frozen_string_literal: true

describe JudgeRepository, :all_dbs do
  before do
    judges = create_list(:staff, 3, :judge_role)
    acting_judges = create_list(:staff, 3, :attorney_judge_role)
    attorneys = create_list(:staff, 3, :attorney_role)
    # These users have an svlj value of "A" that allows them to see reports in vacols, but no attyid because they are
    # not a judge or an attorney. we should not return these users when querying all judges
    reporting_only_users = create_list(:staff, 3, :attorney_judge_role, sattyid: nil)

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
    reporting_only_users.each_with_index do |s, index|
      s.sdomainid = "NON_JUDGE#{index}"
      s.snamef = "NJ#{index}"
    end.map(&:save!)
  end

  context ".find_all_judges" do
    subject { JudgeRepository.find_all_judges }

    it "should return only judges and acting judges" do
      expect(subject.count).to be 6
      expect(subject.pluck(:css_id)).to include("ACTING0", "ACTING1", "ACTING2", "JUDGE0", "JUDGE1", "JUDGE2")
      expect(subject.pluck(:css_id)).not_to include("ATTY0", "ATTY1", "ATTY2", "NON_JUDGE0", "NON_JUDGE1", "NON_JUDGE2")
    end
  end

  context ".find_all_judges_with_name_and_id" do
    subject { JudgeRepository.find_all_judges_with_name_and_id }

    it "should return names of only judges and acting judges" do
      expect(subject.count).to be 6
      expect(subject.pluck(:first_name)).to include("J0", "J1", "J2", "Aj0", "Aj1", "Aj2")
      expect(subject.pluck(:first_name)).not_to include("A0", "A1", "A2", "NJ0", "NJ1", "NJ2")
    end
  end
end
