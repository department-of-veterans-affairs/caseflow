# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe LegacyAppealDispatch, :all_dbs do
  describe "#call" do
    context "invalid or missing citation number" do
      it "raises OutcodeValidationFailure" do
        legacy_appeal = create(:legacy_appeal, vacols_case: create(:case))

        params = {
          appeal_id: legacy_appeal.id
        }

        dispatch = LegacyAppealDispatch.new(appeal: legacy_appeal, params: params)

        expect { dispatch.call }.to raise_error do |e|
          expect(e.class).to eq Caseflow::Error::OutcodeValidationFailure
          expect(e.message).to eq "Validation failed: Citation number is invalid"
        end
      end
    end

    context "missing decision_date" do
      it "raises ActiveRecord::NotNullViolation" do
        legacy_appeal = create(:legacy_appeal, vacols_case: create(:case))

        params = {
          appeal_id: legacy_appeal.id,
          citation_number: "A18123456"
        }

        dispatch = LegacyAppealDispatch.new(appeal: legacy_appeal, params: params)

        expect { dispatch.call }.to raise_error ActiveRecord::NotNullViolation
      end
    end
  end
end
