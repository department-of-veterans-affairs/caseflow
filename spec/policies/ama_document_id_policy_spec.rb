require "rails_helper"

describe AmaDocumentIdPolicy do
  describe "#editable?" do
    context "when case_review is nil" do
      it "returns false" do
        policy = AmaDocumentIdPolicy.new(user: User.new, case_review: nil)

        expect(policy.editable?).to eq false
      end
    end

    context "when user is nil" do
      it "returns false" do
        policy = AmaDocumentIdPolicy.new(user: nil, case_review: build(:attorney_case_review))

        expect(policy.editable?).to eq false
      end
    end

    context "when user id matches the case review's attorney_id" do
      it "returns true" do
        policy = AmaDocumentIdPolicy.new(
          user: User.new(id: 1),
          case_review: build(:attorney_case_review, attorney_id: 1)
        )

        expect(policy.editable?).to eq true
      end
    end

    context "when user id matches the case review's reviewing_judge_id" do
      it "returns true" do
        policy = AmaDocumentIdPolicy.new(
          user: User.new(id: 1),
          case_review: build(:attorney_case_review, reviewing_judge_id: 1)
        )

        expect(policy.editable?).to eq true
      end
    end

    context "when user id does not match the case review's reviewing_judge_id or attorney_id" do
      it "returns false" do
        policy = AmaDocumentIdPolicy.new(
          user: User.new(id: 1),
          case_review: build(:attorney_case_review, reviewing_judge_id: 2, attorney_id: 3)
        )

        expect(policy.editable?).to eq false
      end
    end
  end
end
