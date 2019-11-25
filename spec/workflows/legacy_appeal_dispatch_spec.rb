# frozen_string_literal: true

describe LegacyAppealDispatch do
  describe "#call" do
    context "invalid citation number" do
      it "returns an object with validation errors" do
        legacy_appeal = build_stubbed(:legacy_appeal)

        params = {
          appeal_id: legacy_appeal.id,
          citation_number: "123",
          decision_date: Time.zone.today,
          redacted_document_location: "some/filepath",
          file: "some file"
        }

        dispatch = LegacyAppealDispatch.new(appeal: legacy_appeal, params: params).call

        expect(dispatch).to_not be_success
        expect(dispatch.errors[0]).to eq "Citation number is invalid"
      end
    end

    context "citation number already exists" do
      it "returns an object with validation errors" do
        legacy_appeal = build_stubbed(:legacy_appeal)

        params = {
          appeal_id: legacy_appeal.id,
          citation_number: "A18123456",
          decision_date: Time.zone.today,
          redacted_document_location: "some/filepath",
          file: "some file"
        }

        dispatch = LegacyAppealDispatch.new(appeal: legacy_appeal, params: params)
        allow(dispatch).to receive(:unique_citation_number?).and_return(false)

        expect(dispatch.call).to_not be_success
        expect(dispatch.call.errors[0]).to eq "Citation number already exists"
      end
    end

    context "missing required parameters" do
      it "returns an object with validation errors" do
        legacy_appeal = build_stubbed(:legacy_appeal)

        params = {
          appeal_id: legacy_appeal.id,
          citation_number: "A18123456"
        }

        dispatch = LegacyAppealDispatch.new(appeal: legacy_appeal, params: params).call
        error_message = "Decision date can't be blank, Redacted document " \
                        "location can't be blank, File can't be blank"

        expect(dispatch).to_not be_success
        expect(dispatch.errors[0]).to eq error_message
      end
    end
  end
end
