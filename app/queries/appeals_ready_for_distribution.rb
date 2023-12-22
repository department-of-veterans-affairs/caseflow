class AppealsReadyForDistribution
  HEADERS = {
    docket_number: 'Docket Number',
    docket: 'Docket',
    receipt_date: 'Receipt Date',
    ready_for_distribution_at: 'Ready for Distribution at',
    veteran_file_number: 'Veteran File number',
    veteran_name: 'Veteran',
    hearing_judge: 'Hearing Judge',
    aod: 'AOD',
    cavc: 'CAVC'
  }.freeze

  def self.process
    # Convert results to CSV format

    CSV.generate(headers: true) do |csv|
      # Add headers to CSV
      csv << HEADERS.values

      # Iterate through results and add each row to CSV
      ready_appeals.each do |record|
        csv << HEADERS.keys.map { |k| record[k] }
      end
    end
  end

  def self.ready_appeals
    ready_appeals = []
    docket_coordinator = DocketCoordinator.new

    docket_coordinator.dockets
      .flat_map do |sym, docket|
        appeals = docket.ready_to_distribute_appeals
        if sym == :legacy
          legacy_rows(appeals, sym)
        else
          ama_rows(appeals, sym)
        end
      end
  end

  def self.legacy_rows(appeals, docket)
    appeals.map do |appeal|
      {
        docket_number: appeal["tinum"],
        docket: docket.to_s,
        receipt_date: appeal["bfd19"],
        ready_for_distribution_at: appeal["bfdloout"],
        veteran_file_number: appeal["bfcorlid"],
        veteran_name: nil,
        hearing_judge: appeal["vlj"],
        aod: appeal["aod"] == 1,
        cavc: appeal["cavc"] == 1
      }
    end
  end

  def self.ama_rows(appeals, docket)
    appeals.map do |appeal|
      {
        docket_number: appeal.docket_number,
        docket: docket.to_s,
        receipt_date: appeal.receipt_date,
        ready_for_distribution_at: nil,
        veteran_file_number: appeal.veteran_file_number,
        veteran_name: appeal.veteran&.name.to_s,
        hearing_judge: nil,
        aod: appeal.aod,
        cavc: appeal.cavc
      }
    end
  end
end
