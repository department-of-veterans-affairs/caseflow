# frozen_string_literal: true

describe Colocated, :postgres do
  let(:colocated_org) { Colocated.singleton }
  let(:appeal) { nil }

  before do
    create_list(:user, 6).each do |u|
      colocated_org.add_user(u)
    end
  end

  describe ".automatically_assign_to_member?" do
    subject { colocated_org.automatically_assign_to_member? }

    it "should return false" do
      expect(subject).to eq(false)
    end
  end
end
