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

  describe "#appellant_tz" do
    class TestAppellantAddressClass
      include ActiveModel::Model
      include AppealConcern
      attr_accessor :appellant_address
    end

    let(:country) { nil }
    let(:address_obj) do
      Address.new(
        address_line_1: Faker::Address.street_address,
        city: Faker::Address.city,
        country: country,
        zip: Faker::Number.number(digits: 4).to_s
      )
    end
    let(:model) { TestAppellantAddressClass.new(appellant_address: address_obj) }

    subject { model.appellant_tz }

    context "when the foreign address has a single time zone" do
      let(:country) { "Tanzania" }

      it "Returns the expected timezone identifier" do
        expect(subject).to eq("Africa/Dar_es_Salaam")
      end
    end

    context "when the foreign address spans many time zones" do
      let(:country) { "Australia" }

      it "Returns nil and increments a datadog counter" do
        expect(DataDogService).to receive(:increment_counter).with(
          app_name: nil,
          metric_group: "appeal_timezone_service",
          metric_name: "ambiguous_timezone_error",
          attrs: {
            country_code: "AU"
          }
        )

        expect(subject).to be_nil
      end
    end
  end
end
