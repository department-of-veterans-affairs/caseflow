# frozen_string_literal: true

describe MembershipRequest do
  let(:membership_request) { build(:membership_request) }

  describe "#save" do
    context "when record is valid" do
      it "saves to database" do
        expect { membership_request.save }.to change { MembershipRequest.count }.by(1)
      end
    end

    context "when record is invalid" do
      it "should not save to database" do
        membership_request.status = nil
        membership_request.valid?

        expect(membership_request.errors.full_messages).to be_present
      end
    end
  end
end
