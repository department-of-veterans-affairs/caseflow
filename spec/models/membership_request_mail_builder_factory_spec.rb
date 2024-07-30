# frozen_string_literal: true

describe MembershipRequestMailBuilderFactory, :postgres do
  describe "get mail builder" do
    subject { described_class.get_mail_builder(type) }

    context "invalid type" do
      let(:type) { "InvalidType" }

      it "should return a NotImplementedError" do
        expect(subject).to eq(NotImplementedError)
      end
    end

    context "vha type" do
      let(:type) { "VHA" }
      it "should return the VhaMembershipRequestMailBuilder" do
        expect(subject).to eq(VhaMembershipRequestMailBuilder)
      end
    end
  end
end
