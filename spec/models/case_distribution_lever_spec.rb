# frozen_string_literal: true

RSpec.describe CaseDistributionLever, :all_dbs do
  let!(:levers) { Seeds::CaseDistributionLevers.levers }
  let!(:lever_user) { create(:user) }
  let!(:integer_levers) do
    %w[ama_direct_review_docket_time_goals
       request_more_cases_minimum
       alternative_batch_size
       batch_size_per_attorney
       days_before_goal_due_for_distribution
       ama_hearing_case_affinity_days
       cavc_affinity_days
       ama_evidence_submission_docket_time_goals
       ama_hearings_docket_time_goals]
  end
  let!(:float_levers) do
    %w[maximum_direct_review_proportion minimum_legacy_proportion nod_adjustment]
  end

  describe "validations" do
    it "requires a title" do
      lever = described_class.new(title: nil)
      expect(lever).not_to be_valid
      expect(lever.errors[:title]).to include("can't be blank")
    end

    it "requires a item" do
      lever = described_class.new(item: nil)
      expect(lever).not_to be_valid
      expect(lever.errors[:item]).to include("can't be blank")
    end

    it 'requires a boolean attribute values to be either "true" or "false"' do
      lever = described_class.new
      expect(lever).not_to be_valid
      expect(lever.errors[:is_toggle_active]).to include("is not included in the list")
      expect(lever.errors[:is_disabled_in_ui]).to include("is not included in the list")
    end

    context "validates value matches data_type" do
      it "validates radio data_type" do
        lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days)
        valid = lever.update(options: nil)

        expect(valid).to be_falsey
      end

      it "validates number data_type" do
        lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.request_more_cases_minimum)
        valid = lever.update(value: "abc123")

        expect(valid).to be_falsey
      end

      it "validates boolean data_type" do
        lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.bust_backlog)
        valid = lever.update(value: "abc123")

        expect(valid).to be_falsey
      end

      it "validates combination data_type" do
        lever = CaseDistributionLever.find_by_item(
          Constants.DISTRIBUTION.ama_hearings_start_distribution_prior_to_goals
        )
        valid = lever.update(options: nil)

        expect(valid).to be_falsey
      end
    end

    context "custom validation errors" do
      let(:case_distribution_lever) { described_class.new }

      it "invalid data type" do
        case_distribution_lever.data_type = "float"
        case_distribution_lever.valid?
        expect(case_distribution_lever.errors.full_messages).to include("Data type is not included in the list")
      end

      it "should return error when pass invalid value for number data type" do
        case_distribution_lever.data_type = "number"
        case_distribution_lever.value = "invalid_number"
        case_distribution_lever.valid?
        expect(case_distribution_lever.errors.full_messages).to include(
          "Value does not match its data_type number. Value is invalid_number"
        )
      end

      it "should return error when item is not included in constants" do
        case_distribution_lever.item = "invalid_item"
        case_distribution_lever.data_type = "number"
        case_distribution_lever.valid?
        expect(case_distribution_lever.errors.full_messages).to include(
          "Item is of data_type number but is not included in INTEGER_LEVERS or FLOAT_LEVERS"
        )
      end
    end
  end

  context "constants" do
    it "should match array of INTEGER Levers" do
      expect(CaseDistributionLever::INTEGER_LEVERS).to match_array(integer_levers)
    end

    it "should match array of FLOAT Levers" do
      expect(CaseDistributionLever::FLOAT_LEVERS).to match_array(float_levers)
    end
  end

  context "distribution_value" do
    it "should return value from options value when radio data type lever object" do
      lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days)
      option = lever.options.detect { |opt| opt["item"] == lever.value }
      expect(lever.distribution_value).to eq(option["value"])
    end

    it "should return value from lever object" do
      lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.request_more_cases_minimum)
      expect(lever.distribution_value).to eq(lever.value)
    end
  end

  context "update_acd_levers" do
    it "makes valid lever updates and creates audit entries" do
      request_more_cases_minimum = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.request_more_cases_minimum)
      minimum_legacy_proportion = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.minimum_legacy_proportion)

      lever1 = {
        "id" => request_more_cases_minimum.id,
        "value" => 42
      }

      lever2 = {
        "id" => minimum_legacy_proportion.id,
        "value" => 0.5
      }

      current_levers = [lever1, lever2]

      errors = CaseDistributionLever.update_acd_levers(current_levers, lever_user)
      expect(errors.empty?).to be_truthy

      audit1 = CaseDistributionAuditLeverEntry.where(case_distribution_lever: request_more_cases_minimum).last
      audit2 = CaseDistributionAuditLeverEntry.where(case_distribution_lever: minimum_legacy_proportion).last

      expect(audit1.previous_value).to eq(request_more_cases_minimum.value)
      expect(audit2.previous_value).to eq(minimum_legacy_proportion.value)

      expect(audit1.update_value).to eq(lever1["value"].to_s)
      expect(audit2.update_value).to eq(lever2["value"].to_s)
    end

    it "makes rejects invalid lever updates and creates audit entries" do
      request_more_cases_minimum = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.request_more_cases_minimum)
      minimum_legacy_proportion = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.minimum_legacy_proportion)

      lever1 = {
        "id" => request_more_cases_minimum.id,
        "value" => "abc123"
      }

      lever2 = {
        "id" => minimum_legacy_proportion.id,
        "value" => 0.5
      }

      current_levers = [lever1, lever2]

      errors = CaseDistributionLever.update_acd_levers(current_levers, lever_user)
      expect(errors.size).to eq(1)

      audit1 = CaseDistributionAuditLeverEntry.where(case_distribution_lever: request_more_cases_minimum).last
      audit2 = CaseDistributionAuditLeverEntry.where(case_distribution_lever: minimum_legacy_proportion).last

      expect(request_more_cases_minimum.value).to_not eq(lever1["value"])
      expect(audit1&.update_value).to_not eq(lever1["value"])
      expect(audit2.previous_value).to eq(minimum_legacy_proportion.value)

      expect(audit2.update_value).to eq(lever2["value"].to_s)
    end

    it "should return standard error when pass invalid user" do
      request_more_cases_minimum = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.request_more_cases_minimum)
      minimum_legacy_proportion = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.minimum_legacy_proportion)

      lever1 = {
        "id" => request_more_cases_minimum.id,
        "value" => "abc123"
      }

      lever2 = {
        "id" => minimum_legacy_proportion.id,
        "value" => 0.5
      }
      current_levers = [lever1, lever2]

      errors = CaseDistributionLever.update_acd_levers(current_levers, nil)
      expect(errors.size).to eq(2)
      expect(errors.last.to_s).to include("PG::NotNullViolation: ERROR")
    end
  end
end
