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

  describe "#sanitize" do
    subject { schema.sanitize(params) }

    context "when unknown params are included" do
      let(:params_hash) { { id: 123, name: "foo", unknown: "bar" } }

      it "removes unknown params" do
        subject
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
