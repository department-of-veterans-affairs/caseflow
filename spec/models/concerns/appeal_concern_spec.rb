# frozen_string_literal: true

describe AppealConcern do
  class TestThing
    include ActiveModel::Model
    include AppealConcern
    attr_accessor :regional_office_key
  end

  let(:regional_office_key) { "RO22" }
  let(:model) { TestThing.new(regional_office_key: regional_office_key) }

  context "#regional_office_name" do
    subject { model.regional_office_name }

    it { is_expected.to eq "Montgomery, AL" }
  end

  context "#regional_office" do
    subject { model.regional_office }

    context "when key is not nil" do
      it "matches expected name" do
        expect(subject.name).to eq "Montgomery regional office"
      end
    end

    context "when key is nil" do
      let(:regional_office_key) { nil }

      it "returns nil" do
        expect(subject).to eq nil
      end
    end
  end
end
