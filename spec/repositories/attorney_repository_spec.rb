# frozen_string_literal: true

describe JudgeRepository, :all_dbs do
  let(:staff_count) { 3 }

  let!(:judges) { create_list(:staff, staff_count, :judge_role) }
  let!(:acting_judges) { create_list(:staff, staff_count, :attorney_judge_role) }
  let!(:attorneys) { create_list(:staff, staff_count, :attorney_role) }
  let!(:misc_staff) { create_list(:staff, staff_count, sactive: "I") }

  context ".find_all_having_attorney_ids", skip: "flake" do
    subject { AttorneyRepository.find_all_having_attorney_ids }

    it "should return only active attorneys, judges, and acting judges" do
      expect(subject.length).to eq(judges.count + acting_judges.count + attorneys.count)
    end
  end

  # TODO: test find_all_having_attorney_ids_excluding_judges
end
