# frozen_string_literal: true

class AppealsInLocation63InPast2Days
  HEADERS = {
    docket_number: "Docket Number",
    aod: "AOD",
    cavc: "CAVC",
    receipt_date: "Receipt Date",
    ready_for_distribution_at: "Ready for Distribution at",
    veteran_file_number: "Veteran File number",
    veteran_name: "Veteran",
    hearing_judge_id: "Most Recent Hearing Judge ID",
    hearing_judge_name: "Most Recent Hearing Judge Name",
    deciding_judge_id: "Most Recent Deciding Judge ID",
    deciding_judge_name: "Most Recent Deciding Judge Name",
    affinity_start_date: "Affinity Start Date",
    moved_date_time: "Date/Time Moved",
    bfcurloc: "BFCURLOC"
  }.freeze

  def self.generate_rows(record)
    HEADERS.keys.map { |key| record[key] }
  end

  def self.process
    # Convert results to CSV format

    CSV.generate(headers: true) do |csv|
      # Add headers to CSV
      csv << HEADERS.values

      # Iterate through results and add each row to CSV
      loc_63_appeals.each do |record|
        csv << generate_rows(record)
      end
    end
  end

  def self.loc_63_appeals
    docket_coordinator = DocketCoordinator.new

    docket_coordinator.dockets
      .flat_map do |sym, docket|
        if sym == :legacy
          appeals = docket.loc_63_appeals
          legacy_rows(appeals).uniq { |record| record[:docket_number] }
        else
          []
        end
      end
  end

  def self.legacy_rows(appeals)
    unsorted_result = appeals.map do |appeal|
      calculated_values = calculate_field_values(appeal)
      {
        docket_number: appeal["tinum"],
        aod: appeal["aod"] == 1,
        cavc: appeal["cavc"] == 1,
        receipt_date: appeal["bfd19"],
        ready_for_distribution_at: appeal["bfdloout"],
        veteran_file_number: appeal["ssn"] || appeal["bfcorlid"],
        veteran_name: calculated_values[:veteran_name],
        hearing_judge_id: calculated_values[:hearing_judge_id],
        hearing_judge_name: calculated_values[:hearing_judge_name],
        deciding_judge_id: calculated_values[:deciding_judge_id],
        deciding_judge_name: calculated_values[:deciding_judge_name],
        affinity_start_date: calculated_values[:appeal_affinity]&.affinity_start_date,
        moved_date_time: appeal["bfdlocin"],
        bfcurloc: appeal["bfcurloc"]
      }
    end

    unsorted_result.sort_by { |appeal| appeal[:moved_date_time] }.reverse
  end

  def self.calculate_field_values(appeal)
    vlj_name = FullName.new(appeal["vlj_namef"], nil, appeal["vlj_namel"]).to_s
    {
      veteran_name: FullName.new(appeal["snamef"], nil, appeal["snamel"]).to_s,
      hearing_judge_id: appeal["vlj"].blank? ? nil : legacy_hearing_judge(appeal),
      hearing_judge_name: vlj_name.empty? ? nil : vlj_name,
      deciding_judge_id: appeal["prev_deciding_judge"].blank? ? nil : legacy_original_deciding_judge(appeal),
      deciding_judge_name: appeal["prev_deciding_judge"].blank? ? nil : legacy_original_deciding_judge_name(appeal),
      appeal_affinity: AppealAffinity.find_by(case_id: appeal["bfkey"], case_type: "VACOLS::Case")
    }
  end

  def self.legacy_hearing_judge(appeal)
    staff = VACOLS::Staff.find_by(sattyid: appeal["vlj"])
    staff&.sdomainid || appeal["vlj"]
  end

  def self.legacy_original_deciding_judge(appeal)
    staff = VACOLS::Staff.find_by(sattyid: appeal["prev_deciding_judge"])
    staff&.sdomainid || appeal["prev_deciding_judge"]
  end

  def self.legacy_original_deciding_judge_name(appeal)
    staff = VACOLS::Staff.find_by(sattyid: appeal["prev_deciding_judge"])
    deciding_judge_name = staff.nil? ? "" : FullName.new(staff["snamef"], nil, staff["snamel"]).to_s
    deciding_judge_name.empty? ? nil : deciding_judge_name
  end
end
