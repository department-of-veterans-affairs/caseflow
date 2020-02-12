# frozen_string_literal: true

shared_examples_for "a model that can have a virtual hearing" do
  context ".virtual?" do
    subject { instance_of_class.reload.virtual? }

    context "with an associated virtual hearing" do
      let!(:virtual_hearing) { create(:virtual_hearing, hearing: instance_of_class) }

      it { expect(subject).to be true }
    end

    context "with no associated virtual hearing" do
      it { expect(subject).to be false }
    end
  end
end
