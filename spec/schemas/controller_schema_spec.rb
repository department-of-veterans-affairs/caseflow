# frozen_string_literal: true

describe ControllerSchema do
  let(:params) { ActionController::Parameters.new(params_hash) }
  let(:schema) do
    ControllerSchema.json do
      integer :id
      string :name, nullable: true
      date :date_of_birth, optional: true
    end
  end

  describe "#remove_unknown_keys" do
    subject { schema.remove_unknown_keys(params, known: "foo") }

    context "when unknown params are included" do
      let(:params_hash) { { id: 123, name: "value", known: "foo", unknown: "bar" } }

      it "removes unknown params" do
        subject
        expect(params).to include(:id, :name, :known)
        expect(params).not_to include(:unknown)
      end
    end
  end

  describe "#validate" do
    subject { schema.validate(params) }

    context "when a required param is missing" do
      let(:params_hash) { { name: "foo" } }

      it "returns a failure result" do
        expect(subject.failure?).to be_truthy
      end
    end
  end
end
