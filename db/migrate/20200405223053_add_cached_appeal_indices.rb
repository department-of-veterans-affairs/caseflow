class AddCachedAppealIndices < Caseflow::Migration
  def change
    [
      :case_type,
      :closest_regional_office_city,
      :closest_regional_office_key,
      :docket_type,
      :is_aod,
      :power_of_attorney_name,
      :suggested_hearing_location,
      :veteran_name
    ].each do |column|
      add_safe_index :cached_appeal_attributes, column
    end
  end
end
