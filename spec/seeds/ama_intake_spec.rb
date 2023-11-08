# frozen_string_literal: true

describe Seeds::AmaIntake do
  let(:seed) { Seeds::AmaIntake.new }

  let(:veteran_appeal_request_issues) do
    RequestIssue.where(decision_review: Appeal.first,
                       veteran_participant_id: Veteran.first.participant_id)
  end

  let(:veteran_decision_issues_for_appeal_request_issues) do
    veteran_appeal_request_issues.map(&:decision_issues)
  end

  let(:veteran_hlr_request_issues) do
    RequestIssue.where(decision_review: HigherLevelReview.first,
                       veteran_participant_id: Veteran.first.participant_id)
  end

  let(:veteran_decision_issues_for_hlr_request_issues) do
    veteran_hlr_request_issues.map(&:decision_issues)
  end

  let(:veteran_sc_request_issues) do
    RequestIssue.where(decision_review: SupplementalClaim.first,
                       veteran_participant_id: Veteran.first.participant_id)
  end

  let(:veteran_decision_issues_for_sc_request_issues) do
    veteran_sc_request_issues.map(&:decision_issues)
  end

  let(:veteran_hlr_decision_issues) do
    DecisionIssue.where(decision_review: HigherLevelReview.first,
                        participant_id: Veteran.first.participant_id)
  end

  let(:veteran_request_issues_for_hlr_decision_issues) do
    veteran_hlr_decision_issues.map(&:request_issues)
  end

  context "#seed!" do
    it "seeds total of 7 Veterans, 15 Legacy Appeals, 6 Appeals, 6 Higher Level Reviews End Product Establishments,
      2 Supplemental Claim End Product Establishments, 940 Request Issues, and 894 Decision Issues" do
      seed.seed!
      expect(Veteran.count).to eq(7)
      expect(VACOLS::Case.all.size).to eq(15)
      expect(Appeal.count).to eq(6)
      expect(HigherLevelReview.count).to eq(6)
      expect(SupplementalClaim.count).to eq(2)
      expect(EndProductEstablishment.count).to eq(8)
      expect(RequestIssue.count).to eq(940)
      expect(DecisionIssue.count).to eq(894)
    end
  end

  context "#create_veteran_with_no_legacy_appeals_and_many_request_and_decision_issues" do
    before do
      seed.send(:create_veteran_with_no_legacy_appeals_and_many_request_and_decision_issues)
    end

    it "the Veteran has 3 decision reviews: one Appeal, one Higher Level Review, and one Supplemental Claim" do
      expect(Appeal.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(SupplementalClaim.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
    end

    it "the Veteran has no Legacy Appeals in VACOLS" do
      expect(VACOLS::Case.all.size).to eq(0)
    end

    it "the Veteran's Appeal has 180 Request Issues, each containing a Decision Issue" do
      expect(veteran_appeal_request_issues.size).to eq(180)
      expect(veteran_decision_issues_for_appeal_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the Veteran's Higher Level Review has 180 Request Issues, each containing a Decision Issue" do
      expect(veteran_hlr_request_issues.size).to eq(180)
      expect(veteran_decision_issues_for_hlr_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the Veteran's Supplemental Claim has 60 Request Issues, none of which contain a Decision Issue" do
      expect(veteran_sc_request_issues.size).to eq(60)
      expect(veteran_decision_issues_for_sc_request_issues.all?(&:empty?)).to eq(true)
    end
  end

  context "#create_veteran_with_legacy_appeals_and_many_request_and_decision_issues" do
    before do
      seed.send(:create_veteran_with_legacy_appeals_and_many_request_and_decision_issues)
    end

    it "the Veteran has 3 decision reviews: one Appeal, one Higher Level Review, and one Supplemental Claim" do
      expect(Appeal.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(SupplementalClaim.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
    end

    it "the Veteran has 5 Legacy Appeals in VACOLS" do
      expect(VACOLS::Case.all.size).to eq(5)
    end

    it "the Veteran's Appeal has 180 Request Issues, each containing a Decision Issue" do
      expect(veteran_appeal_request_issues.size).to eq(180)
      expect(veteran_decision_issues_for_appeal_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the Veteran's Higher Level Review has 180 Request Issues, each containing a Decision Issue" do
      expect(veteran_hlr_request_issues.size).to eq(180)
      expect(veteran_decision_issues_for_hlr_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the Veteran's Supplemental Claim has 60 Request Issues, none of which contain a Decision Issue" do
      expect(veteran_sc_request_issues.size).to eq(60)
      expect(veteran_decision_issues_for_sc_request_issues.all?(&:empty?)).to eq(true)
    end
  end

  context "#create_veteran_with_no_legacy_appeals_and_request_issue_with_many_decision_issues" do
    before do
      seed.send(:create_veteran_with_no_legacy_appeals_and_request_issue_with_many_decision_issues)
    end

    it "the Veteran has 2 decision reviews: one Appeal and one Higher Level Review" do
      expect(Appeal.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
    end

    it "the Veteran's Appeal has 7 Request Issues, each containing a Decision Issue" do
      expect(veteran_appeal_request_issues.size).to eq(7)
      expect(veteran_decision_issues_for_appeal_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the Veteran's Higher Level Review has 8 Request Issues, 7 containing a single Decision Issue" do
      expect(veteran_hlr_request_issues.size).to eq(8)
      expect(veteran_decision_issues_for_hlr_request_issues.count { |array| array.size == 1 }).to eq(7)
    end

    it "one Request Issue on the Veteran's Higher Level Review is associated with 68 Decision Issues" do
      expect(veteran_decision_issues_for_hlr_request_issues.count { |array| array.size == 68 }).to eq(1)
    end
  end

  context "#create_veteran_with_legacy_appeals_and_request_issue_with_many_decision_issues" do
    before do
      seed.send(:create_veteran_with_legacy_appeals_and_request_issue_with_many_decision_issues)
    end

    it "the Veteran has 2 decision reviews: one Appeal and one Higher Level Review" do
      expect(Appeal.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
    end

    it "the Veteran has 5 Legacy Appeals in VACOLS" do
      expect(VACOLS::Case.all.size).to eq(5)
    end

    it "the Veteran's Appeal has 7 Request Issues, each containing a Decision Issue" do
      expect(veteran_appeal_request_issues.size).to eq(7)
      expect(veteran_decision_issues_for_appeal_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the Veteran's Higher Level Review has 8 Request Issues, 7 containing a single Decision Issue" do
      expect(veteran_hlr_request_issues.size).to eq(8)
      expect(veteran_decision_issues_for_hlr_request_issues.count { |array| array.size == 1 }).to eq(7)
    end

    it "one Request Issue on the Veteran's Higher Level Review is associated with 68 Decision Issues" do
      expect(veteran_decision_issues_for_hlr_request_issues.count { |array| array.size == 68 }).to eq(1)
    end
  end

  context "#create_veteran_with_no_legacy_appeals_and_decision_issue_with_many_request_issues" do
    before do
      seed.send(:create_veteran_with_no_legacy_appeals_and_decision_issue_with_many_request_issues)
    end

    it "the Veteran has 2 decision reviews: one Appeal and one Higher Level Review" do
      expect(Appeal.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
    end

    it "the Veteran's Appeal has 2 Request Issues, each containing a Decision Issue" do
      expect(veteran_appeal_request_issues.size).to eq(2)
      expect(veteran_decision_issues_for_appeal_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the Veteran's Higher Level Review has 33 Request Issues, two containing a single Decision Issue" do
      expect(veteran_hlr_request_issues.size).to eq(33)
      expect(veteran_request_issues_for_hlr_decision_issues.count { |array| array.size == 1 }).to eq(2)
    end

    it "one Decision Issue on the Veteran's Higher Level Review is associated with 31 Request Issues" do
      expect(veteran_hlr_decision_issues.count { |di| di.request_issues.size == 31 }).to eq(1)
    end
  end

  context "#create_veteran_with_legacy_appeals_and_decision_issue_with_many_request_issues" do
    before do
      seed.send(:create_veteran_with_legacy_appeals_and_decision_issue_with_many_request_issues)
    end

    it "the Veteran has 2 decision reviews: one Appeal and one Higher Level Review" do
      expect(Appeal.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
      expect(HigherLevelReview.where(veteran_file_number: Veteran.first.file_number).size).to eq(1)
    end

    it "the Veteran has 5 Legacy Appeals in VACOLS" do
      expect(VACOLS::Case.all.size).to eq(5)
    end

    it "the Veteran's Appeal has 2 Request Issues, each containing a Decision Issue" do
      expect(veteran_appeal_request_issues.size).to eq(2)
      expect(veteran_decision_issues_for_appeal_request_issues.all? { |di_array| di_array.size == 1 }).to eq(true)
    end

    it "the Veteran's Higher Level Review has 33 Request Issues, two containing a single Decision Issue" do
      expect(veteran_hlr_request_issues.size).to eq(33)
      expect(veteran_request_issues_for_hlr_decision_issues.count { |array| array.size == 1 }).to eq(2)
    end

    it "one Decision Issue on the Veteran's Higher Level Review is associated with 31 Request Issues" do
      expect(veteran_hlr_decision_issues.count { |di| di.request_issues.size == 31 }).to eq(1)
    end
  end

  context "#create_veteran_without_request_issues" do
    before do
      seed.send(:create_veteran_without_request_issues)
    end

    it "A Veteran is created with 0 Request Issues" do
      expect(Veteran.count).to eq(1)
      expect(veteran_appeal_request_issues.size).to eq(0)
    end
  end
end
