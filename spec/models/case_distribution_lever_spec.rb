RSpec.describe CaseDistributionLever, :all_dbs do
  let!(:levers) {Seeds::CaseDistributionLevers.new.levers}
  let!(:lever_user) { create(:user) }

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
      lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_hearings_start_distribution_prior_to_goals)
      valid = lever.update(options: nil)

      expect(valid).to be_falsey
    end
  end

  context "find_integer_lever" do
    it "returns integer value for lever" do
      lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.request_more_cases_minimum)

      integer_value = CaseDistributionLever.find_integer_lever(Constants.DISTRIBUTION.request_more_cases_minimum)

      expect(lever.value.to_i).to eq(integer_value)
    end

    it "returns float value for lever" do
      lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.minimum_legacy_proportion)

      float_value = CaseDistributionLever.find_float_lever(Constants.DISTRIBUTION.minimum_legacy_proportion)

      expect(lever.value.to_f).to eq(float_value)
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
      expect(audit1.update_value).to_not eq(lever1["value"])
      expect(audit2.previous_value).to eq(minimum_legacy_proportion.value)

      expect(audit2.update_value).to eq(lever2["value"].to_s)
    end
  end
end
