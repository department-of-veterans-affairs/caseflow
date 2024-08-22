# frozen_string_literal: true

class AppealsTiedToNonSscAvljQuery
  # define CSV headers and use this to pull fields to maintain order

  HEADERS = {
    docket_number: "Docket number",
    docket: "Docket type",
    priority: "Priority",
    receipt_date: "Receipt Date",
    veteran_file_number: "File Number",
    veteran_name: "Veteran Name",
    non_ssc_avlj: "Non-SSC AVLJ's Name",
    hearing_judge: "Most-recent hearing judge",
    most_recent_signing_judge: "Most-recent judge who signed decision",
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
      tied_appeals.each do |record|
        csv << generate_rows(record)
      end
    end
  end

  # Uses DocketCoordinator to pull appeals ready for distribution
  # DocketCoordinator is used by Automatic Case Distribution so this will give us the most accurate list of appeals
  def self.tied_appeals
    docket_coordinator = DocketCoordinator.new

    docket_coordinator.dockets
      .flat_map do |sym, docket|
        if sym == :legacy
          appeals = docket.appeals_tied_to_non_ssc_avljs
          unique_appeals = legacy_rows(appeals, sym).uniq { |record| record[:docket_number] }

          unique_appeals
        else
          []
        end
      end
  end

  def self.legacy_rows(appeals, sym)
    appeals.map do |appeal|
      calculated_values = calculate_field_values(appeal)
      {
        docket_number: appeal["tinum"],
        docket: sym.to_s,
        priority: appeal["priority"] == 1 ? "True" : "",
        receipt_date: appeal["bfd19"],
        veteran_file_number: calculated_values[:veteran_file_number],
        veteran_name: calculated_values[:veteran_name],
        non_ssc_avlj: calculated_values[:non_ssc_avlj],
        hearing_judge: calculated_values[:hearing_judge],
        most_recent_signing_judge: calculated_values[:most_recent_signing_judge],
        bfcurloc: calculated_values[:bfcurloc]
      }
    end
  end

  def self.calculate_field_values(appeal)
    avlj_name = get_avlj_name(appeal)
    prev_judge_name = get_prev_judge_name(appeal)
    vacols_case = VACOLS::Case.find_by(bfkey: appeal["bfkey"])
    veteran_record = VACOLS::Correspondent.find_by(stafkey: vacols_case.bfcorkey)
    {
      veteran_file_number: veteran_record.ssn || vacols_case&.bfcorlid,
      veteran_name: get_name_from_record(veteran_record),
      non_ssc_avlj: avlj_name,
      hearing_judge: avlj_name,
      most_recent_signing_judge: prev_judge_name,
      bfcurloc: vacols_case&.bfcurloc
    }
  end

  def self.get_avlj_name(appeal)
    if appeal["vlj"].nil?
      avlj_name = nil
    else
      avlj_record = VACOLS::Staff.find_by(sattyid: appeal["vlj"])
      avlj_name = get_name_from_record(avlj_record)
    end

    avlj_name
  end

  def self.get_prev_judge_name(appeal)
    if appeal["prev_deciding_judge"].nil?
      prev_judge_name = nil
    else
      prev_judge_record = VACOLS::Staff.find_by(sattyid: appeal["prev_deciding_judge"])
      prev_judge_name = get_name_from_record(prev_judge_record)
    end

    prev_judge_name
  end

  def self.get_name_from_record(record)
    FullName.new(record["snamef"], nil, record["snamel"]).to_s
  end
end
