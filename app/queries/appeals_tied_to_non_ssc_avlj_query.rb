# frozen_string_literal: true

class AppealsTiedToNonSscAvljQuery
  # define CSV headers and use this to pull fields to maintain order

  HEADERS = {
    docket_number: "Docket number",
    docket: "Docket type",
    aod: "AOD",
    cavc: "CAVC",
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
      ready_appeals.each do |record|
        csv << generate_rows(record)
      end
    end
  end

  # Uses DocketCoordinator to pull appeals ready for distribution
  # DocketCoordinator is used by Automatic Case Distribution so this will give us the most accurate list of appeals
  def self.ready_appeals
    docket_coordinator = DocketCoordinator.new

    # Returns Appeals Tied to Non SSC AVLJs
    appeals_tied_to_non_ssc_avljs = ReturnedAppealJob.last
    docket_coordinator.dockets
      .flat_map do |sym, docket|
        appeals = docket.ready_to_distribute_appeals # Returns Ready to Distribute Appeals

        # Does not work, returns empty array. Comment out to see CSV populate data.
        appeals = appeals.select { |appeal| appeals_tied_to_non_ssc_avljs.returned_appeals.include?(appeal["bfkey"]) }

        legacy_rows(appeals, sym)
      end
  end

  def self.legacy_rows(appeals, sym)
    appeals.map do |appeal|
      veteran_name = FullName.new(appeal["snamef"], nil, appeal["snamel"]).to_s
      vlj_name = FullName.new(appeal["vlj_namef"], nil, appeal["vlj_namel"]).to_s
      hearing_judge = vlj_name.empty? ? nil : vlj_name
      vacols_case = VACOLS::Case.find_by(bfkey: appeal["bfkey"])

      {
        docket_number: appeal["tinum"],
        docket: sym.to_s,
        aod: appeal["aod"] == 1,
        cavc: appeal["cavc"] == 1,
        receipt_date: appeal["bfd19"],
        veteran_file_number: appeal["ssn"] || appeal["bfcorlid"],
        veteran_name: veteran_name,
        non_ssc_avlj: vlj_name,
        hearing_judge: hearing_judge,
        most_recent_signing_judge: mrsj_name(vacols_case),
        bfcurloc: vacols_case&.bfcurloc
      }
    end
  end

  private

  def mrsj_name(vacols_case)
    vacols_staff = vacols_case && vacols_case&.bfmemid ? VACOLS::Staff.find_by(sattyid: vacols_case.bfmemid) : nil
    vacols_staff ? FullName.new(vacols_staff.snamef, nil, vacols_staff.snamel).to_s : ""
  end
end
