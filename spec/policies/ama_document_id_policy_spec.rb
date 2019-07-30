# frozen_string_literal: true

describe AmaDocumentIdPolicy do
  describe "#editable?" do
    context "when case_review is nil" do
      it "returns false" do
        policy = AmaDocumentIdPolicy.new(user: build_stubbed(:user), case_review: nil)

        expect(policy.editable?).to eq false
      end
    end

    context "when user is nil" do
      it "returns false" do
        policy = AmaDocumentIdPolicy.new(user: nil, case_review: build_stubbed(:attorney_case_review))

        expect(policy.editable?).to eq false
      end
    end

    context "when user id matches the case review's attorney_id" do
      it "returns true" do
        user = build_stubbed(:user)
        policy = AmaDocumentIdPolicy.new(
          user: user,
          case_review: build_stubbed(:attorney_case_review, attorney_id: user.id)
        )

        expect(policy.editable?).to eq true
      end
    end

    context "when user id matches the case review's reviewing_judge_id" do
      it "returns true" do
        user = build_stubbed(:user)
        policy = AmaDocumentIdPolicy.new(
          user: user,
          case_review: build_stubbed(:attorney_case_review, reviewing_judge_id: user.id)
        )

        expect(policy.editable?).to eq true
      end
    end

    context "when user id does not match the case review's reviewing_judge_id or attorney_id" do
      it "returns false" do
        judge = build_stubbed(:user)
        attorney = build_stubbed(:user)
        policy = AmaDocumentIdPolicy.new(
          user: build_stubbed(:user),
          case_review: build_stubbed(:attorney_case_review, reviewing_judge_id: judge.id, attorney_id: attorney.id)
        )

        expect(policy.editable?).to eq false
      end
    end
  end
end
