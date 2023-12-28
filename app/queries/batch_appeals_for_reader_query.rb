# frozen_string_literal: true

class BatchAppealsForReaderQuery
  HEADERS = {
    docket_number: 'Docket Number',
    docket: 'Docket',
    aod: 'AOD',
    cavc: 'CAVC',
    receipt_date: 'Receipt Date',
    ready_for_distribution_at: 'Ready for Distribution at',
    distributed_at: 'Distributed At',
    hearing_judge: 'Hearing Judge',
    veteran_file_number: 'Veteran File number',
    veteran_name: 'Veteran'
  }.freeze

  def self.process

    # Convert results to CSV format
    csv_data = CSV.generate(headers: true) do |csv|
      # Add headers to CSV
      csv << HEADERS.values

      # Iterate through results and add each row to CSV
      distributed_appeals.each do |record|
        csv << HEADERS.keys.map { |k| record[k] }
      end
    end
  end

  # .where(created_at: Date.today - 10.days..Date.today)
  def self.distributed_appeals
      DistributedCase.all.map do |distributed_case|
        if distributed_case.ama_docket
          ama_appeal(distributed_case)
        else
          legacy_appeal(distributed_case)
        end
      end
  end

  def self.ama_appeal(distributed_case)
    appeal = Appeal.find_by_uuid(distributed_case.case_id)
    hearing_judge = appeal.hearings
      .filter{ |h| h.disposition = Constants.HEARING_DISPOSITION_TYPES.held}
      .first&.judge&.full_name

    {
      docket_number: appeal.docket_number,
      docket: distributed_case.docket,
      aod: appeal.aod,
      cavc: appeal.cavc,
      receipt_date: appeal.receipt_date,
      ready_for_distribution_at: distributed_case.ready_at,
      distributed_at: distributed_case.created_at,
      hearing_judge: hearing_judge,
      veteran_file_number: appeal.veteran_file_number,
      veteran_name: appeal.veteran&.name.to_s

    }
  end

  def self.legacy_appeal(distributed_case)
    {
      docket_number: 'Docket Number',
      docket: distributed_case.docket,
      aod: 'AOD',
      cavc: 'CAVC',
      receipt_date: 'Receipt Date',
      ready_for_distribution_at: distributed_case.ready_at,
      distributed_at: distributed_case.created_at,
      hearing_judge: 'Hearing Judge',
      veteran_file_number: 'Veteran File number',
      veteran_name: 'Veteran'
    }
  end
end
