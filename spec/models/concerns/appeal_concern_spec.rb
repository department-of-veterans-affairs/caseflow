# frozen_string_literal: true

describe AppealConcern do
  class TestThing
    include ActiveModel::Model
    include AppealConcern
    attr_accessor :regional_office_key
  end

  let(:model) { TestThing.new(regional_office_key: "RO22") }

  context "#regional_office_name" do
    subject { model.regional_office_name }

    it { is_expected.to eq "Montgomery, AL" }
  end
end
