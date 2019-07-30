# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe JudgeRepository, :all_dbs do
  let(:judge_name) { "Sojudgey" }

  before do
    3.times do
      create(:staff, :judge_role, snamef: judge_name)
    end

    3.times do
      create(:staff, :attorney_judge_role, snamef: judge_name)
    end

    3.times do
      create(:staff, :attorney_role)
    end
  end

  context ".find_all_judges" do
    subject { JudgeRepository.find_all_judges }

    it "should return only judges and acting judges" do
      expect(subject.length).to eq(6)
    end
  end

  context ".find_all_judges_with_name_and_id" do
    subject { JudgeRepository.find_all_judges_with_name_and_id }

    it "should return only judges and acting judges" do
      expect(subject.length).to eq(6)
    end

    it "should return names" do
      expect(subject[0][:first_name]).to eq("Sojudgey")
    end
  end
end
