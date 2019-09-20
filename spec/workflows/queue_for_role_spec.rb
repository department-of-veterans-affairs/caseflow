# frozen_string_literal: true

describe QueueForRole do
  let(:role) { nil }

  subject { QueueForRole.new(role).create(user: create(:user)) }

  context "for an attorney" do
    let(:role) { "attorney" }

    it { expect(subject).to be_instance_of(AttorneyQueue) }
  end

  context "for a judge" do
    let(:role) { "judge" }

    it { expect(subject).to be_instance_of(GenericQueue) }
  end

  context "for a nil role" do
    it { expect { subject }.to raise_error(ArgumentError) }
  end
end
