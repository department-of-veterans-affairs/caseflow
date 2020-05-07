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

  context ".hearing_location_or_regional_office" do
    subject { instance_of_class.reload.hearing_location_or_regional_office }

    context "hearing location is nil" do
      it "returns regional office" do
        instance_of_class.update!(hearing_location: nil)
        expect(subject).to eq(instance_of_class.reload.regional_office)
      end
    end

    context "hearing location is not nil" do
      it "returns hearing location" do
        # binding.pry
        expect(subject).to eq(instance_of_class.reload.location)
      end
    end
  end
end
