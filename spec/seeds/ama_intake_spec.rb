# frozen_string_literal: true

describe Seeds::AmaIntake do
  let!(:seed) { Seeds::AmaIntake.new }

  let!(:first_veteran_appeal_request_issues) do
    RequestIssue.where(decision_review: Appeal.first,
                       veteran_participant_id: Veteran.first.participant_id)
  end

  let!(:first_veteran_decision_issues_for_appeal_request_issues) do
    first_veteran_appeal_request_issues.map(&:decision_issues)
  end

  let!(:first_veteran_hlr_request_issues) do
    RequestIssue.where(decision_review: HigherLevelReview.first,
                       veteran_participant_id: Veteran.first.participant_id)
  end

  let!(:first_veteran_decision_issues_for_hlr_request_issues) do
    first_veteran_hlr_request_issues.map(&:decision_issues)
  end

  let!(:first_veteran_sc_request_issues) do
    RequestIssue.where(decision_review: SupplementalClaim.first,
                       veteran_participant_id: Veteran.first.participant_id)
  end

  let!(:first_veteran_decision_issues_for_sc_request_issues) do
    first_veteran_sc_request_issues.map(&:decision_issues)
  end

  let!(:second_veteran_appeal_request_issues) do
    RequestIssue.where(decision_review: Appeal.second,
                       veteran_participant_id: Veteran.second.participant_id)
  end

  let!(:second_veteran_decision_issues_for_appeal_request_issues) do
    second_veteran_appeal_request_issues.map(&:decision_issues)
  end

  let!(:second_veteran_hlr_request_issues) do
    RequestIssue.where(decision_review: HigherLevelReview.second,
                       veteran_participant_id: Veteran.second.participant_id)
  end

  let!(:second_veteran_decision_issues_for_hlr_request_issues) do
    second_veteran_hlr_request_issues.map(&:decision_issues)
  end

  let!(:second_veteran_sc_request_issues) do
    RequestIssue.where(decision_review: SupplementalClaim.second,
                       veteran_participant_id: Veteran.second.participant_id)
  end

  let!(:second_veteran_decision_issues_for_sc_request_issues) do
    second_veteran_sc_request_issues.map(&:decision_issues)
  end

  context "#seed!" do
    it "seeds total of 6 Veterans, 5 Appeals, 6 Higher Level Reviews End Product Establishments,
      2 Supplemental Claim End Product Establishments, 803 Request Issues, and 748 Decision Issues" do
      seed.seed!
      expect(Veteran.count).to eq(6)
      expect(HigherLevelReview.count).to eq(6)
      expect(SupplementalClaim.count).to eq(2)
      expect(RequestIssue.count).to eq(803)
      expect(DecisionIssue.count).to eq(748)
    end
  end

  context "#create_two_veterans_with_many_request_and_decision_issues" do
    before do
      seed.send(:create_two_veterans_with_many_request_and_decision_issues)
    end

    it "seeds total of 2 Veterans, 2 Appeals, 2 Higher Level Reviews, 2 Supplemental Claims,
    700 Request Issues, and 600 Decision Issues" do
      expect(Veteran.count).to eq(2)
      expect(Appeal.count).to eq(2)
      expect(HigherLevelReview.count).to eq(2)
      expect(SupplementalClaim.count).to eq(2)
      expect(EndProductEstablishment.count).to eq(4)
      expect(RequestIssue.count).to eq(700)
      expect(DecisionIssue.count).to eq(600)
    end

    it "the first Veteran has 3 decision reviews: one Appeal, one Higher Level Review, and one Supplemental Claim" do
      expect(Appeal.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(SupplementalClaim.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
    end

    it "the first Veteran's Appeal has 180 Request Issues, each containing a Decision Issue" do
      expect(first_veteran_appeal_request_issues.size).to eq(180)
      expect(first_veteran_decision_issues_for_appeal_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the first Veteran's Higher Level Review has 180 Request Issues, each containing a Decision Issue" do
      expect(first_veteran_hlr_request_issues.size).to eq(180)
      expect(first_veteran_decision_issues_for_hlr_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the first Veteran's Supplemental Claim has 60 Request Issues, none of which containing a Decision Issue" do
      expect(first_veteran_sc_request_issues.size).to eq(60)
      expect(first_veteran_decision_issues_for_sc_request_issues.all?(&:empty?)).to eq(true)
    end

    it "the second Veteran has 3 decision reviews: one Appeal, one Higher Level Review, and one Supplemental Claim" do
      expect(Appeal.where(veteran_file_number: Veteran.second.file_number).size).to eq(1)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.second.file_number).size).to eq(1)
      expect(SupplementalClaim.where(veteran_file_number: Veteran.second.file_number).size).to eq(1)
    end

    it "the second Veteran's Appeal has 120 Request Issues, each containing a Decision Issue" do
      expect(second_veteran_appeal_request_issues.size).to eq(120)
      expect(second_veteran_decision_issues_for_appeal_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the second Veteran's Higher Level Review has 120 Request Issues, each containing a Decision Issue" do
      expect(second_veteran_hlr_request_issues.size).to eq(120)
      expect(second_veteran_decision_issues_for_hlr_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the second Veteran's Supplemental Claim has 40 Request Issues, none of which containing a Decision Issue" do
      expect(second_veteran_sc_request_issues.size).to eq(40)
      expect(second_veteran_decision_issues_for_sc_request_issues.all?(&:empty?)).to eq(true)
    end
  end

  context "#create_two_veterans_with_request_issue_with_many_decision_issues" do
    before do
      seed.send(:create_two_veterans_with_request_issue_with_many_decision_issues)
    end

    it "seeds total of 2 Veterans, 1 Appeal, 2 Higher Level Reviews, 18 Request Issues, and 117 Decision Issues" do
      expect(Veteran.count).to eq(2)
      expect(Appeal.count).to eq(1)
      expect(HigherLevelReview.count).to eq(2)
      expect(SupplementalClaim.count).to eq(0)
      expect(EndProductEstablishment.count).to eq(2)
      expect(RequestIssue.count).to eq(18)
      expect(DecisionIssue.count).to eq(117)
    end

    it "the first Veteran has 2 decision reviews: one Appeal and one Higher Level Review" do
      expect(Appeal.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
    end

    it "the first Veteran's Appeal has 7 Request Issues, each containing a Decision Issue" do
      expect(first_veteran_appeal_request_issues.size).to eq(7)
      expect(first_veteran_decision_issues_for_appeal_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the first Veteran's Higher Level Review has 8 Request Issues, the first 7 containing a single Decision Issue" do
      expect(first_veteran_hlr_request_issues.size).to eq(8)
      expect(first_veteran_decision_issues_for_hlr_request_issues.first(7).all? { |array| array.size == 1 }).to eq(true)
    end

    it "the last Request Issue on the first Veteran's Higher Level Review is associated with 68 Decision Issues" do
      expect(first_veteran_decision_issues_for_hlr_request_issues.last.size).to eq(68)
    end

    it "the second Veteran has 1 decision review: a Higher Level Review" do
      expect(Appeal.where(veteran_file_number: Veteran.second.file_number).size).to eq(0)
      expect(SupplementalClaim.where(veteran_file_number: Veteran.second.file_number).size).to eq(0)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.second.file_number).size).to eq(1)
    end

    it "the second Veteran's Higher Level Review has 3 Request Issues, the first two containing a Decision Issue" do
      expect(second_veteran_hlr_request_issues.size).to eq(3)
      expect(second_veteran_decision_issues_for_hlr_request_issues.first(2).all? { |arr| arr.size == 1 }).to eq(true)
    end

    it "the last Request Issue on the second Veteran's Higher Level Review is associated with 33 Decision Issues" do
      expect(second_veteran_decision_issues_for_hlr_request_issues.last.size).to eq(33)
    end
  end

  context "#create_two_veterans_with_decision_issue_with_many_request_issues" do
    before do
      seed.send(:create_two_veterans_with_decision_issue_with_many_request_issues)
    end

    it "seeds total of 2 Veterans, 2 Appeals, 2 Higher Level Reviews, 85 Request Issues, and 31 Decision Issues" do
      expect(Veteran.count).to eq(2)
      expect(Appeal.count).to eq(2)
      expect(HigherLevelReview.count).to eq(2)
      expect(SupplementalClaim.count).to eq(0)
      expect(EndProductEstablishment.count).to eq(2)
      expect(RequestIssue.count).to eq(85)
      expect(DecisionIssue.count).to eq(31)
    end

    it "the first Veteran has 2 decision reviews: one Appeal and one Higher Level Review" do
      expect(Appeal.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
    end

    it "the first Veteran's Appeal has 2 Request Issues, each containing a Decision Issue" do
      expect(first_veteran_appeal_request_issues.size).to eq(2)
      expect(first_veteran_decision_issues_for_appeal_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the first Veteran's Higher Level Review has 3 Request Issues, the first 2 containing a single Decision Issue" do
      expect(first_veteran_hlr_request_issues.size).to eq(33)
      expect(first_veteran_decision_issues_for_hlr_request_issues.first(2).all? { |array| array.size == 1 }).to eq(true)
    end

    it "the last Decision Issue on the first Veteran's Higher Level Review is associated with 31 Request Issues" do
      expect(first_veteran_decision_issues_for_hlr_request_issues.flatten.last.request_issues.size).to eq(31)
    end

    it "the second Veteran has 2 decision reviews: one Appeal and one Higher Level Review" do
      expect(Appeal.where(veteran_file_number: Veteran.second.file_number).size).to eq(1)
      expect(SupplementalClaim.where(veteran_file_number: Veteran.second.file_number).size).to eq(0)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.second.file_number).size).to eq(1)
    end

    it "the second Veteran's Appeal has 12 Request Issues, each containing a Decision Issue" do
      expect(second_veteran_appeal_request_issues.size).to eq(12)
      expect(second_veteran_decision_issues_for_appeal_request_issues.all? { |arr| arr.size == 1 }).to eq(true)
    end

    it "the second Veteran's Higher Level Review has 38 Request Issues, the first 13 containing a Decision Issue" do
      expect(second_veteran_hlr_request_issues.size).to eq(38)
      expect(second_veteran_decision_issues_for_hlr_request_issues.first(13).all? { |arr| arr.size == 1 }).to eq(true)
    end

    it "the last Decision Issue on the second Veteran's Higher Level Review is associated with 25 Request Issues" do
      expect(second_veteran_decision_issues_for_hlr_request_issues.flatten.last.request_issues.size).to eq(25)
    end
  end
end
