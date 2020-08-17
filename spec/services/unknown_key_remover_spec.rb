# frozen_string_literal: true

describe UnknownKeyRemover do
  let(:params) { ActionController::Parameters.new(params_hash) }
  let(:schema) do
    ControllerSchema.json do |schema|
      schema.integer :id
      schema.string :name, nullable: true
      schema.date :date_of_birth, optional: true
    end
  end

  shared_context "nested_schema" do
    let(:schema) do
      ControllerSchema.json do |schema|
        schema.nested :inner,
                      optional: true,
                      nullable: true do |nested|
                        nested.string :field, optional: false, nullable: false
                      end
      end
    end
  end

  describe "#remove_unknown_keys_in_place" do
    subject do
      UnknownKeyRemover
        .new(schema)
        .remove_unknown_keys_in_place(params, path_params: { known: "foo" })
    end

    context "when unknown params are included" do
      let(:params_hash) { { id: 123, name: "value", known: "foo", unknown: "bar" } }

      it "removes unknown params" do
        subject
        expect(params).to include(:id, :name, :known)
        expect(params).not_to include(:unknown)
      end
    end

    context "for nested schema" do
      include_context "nested_schema"

      context "when unknown params are included in nested field" do
        let(:params_hash) { { inner: { field: "hello", not_field: 123 }, outer_not_field: 123 } }

        it "removes unknown params" do
          subject
          expect(params).to include(:inner)
          expect(params).not_to include(:outer_not_field)
          expect(params[:inner]).to include(:field)
          expect(params[:inner]).not_to include(:not_field)
        end
      end
    end
  end
end
