# frozen_string_literal: true

class Hearings::WorkOrderFileJob < CaseflowJob
  queue_with_priority :low_priority

  S3_BUCKET = "vaec-appeals-caseflow"
  TMP_FOLDER = Rails.root.join("tmp")

  def perform(work_order)
    @file_name = nil
    @file_path = nil
    work_book = create_spreadsheet(work_order)
    write_to_workbook(work_book, work_order[:work_order_name])
    upload_to_s3
    cleanup_tmp_file
  end

  private

  def create_spreadsheet(work_order)
    workbook =  Spreadsheet::Workbook.new
    worksheet = workbook.create_worksheet

    worksheet.row(0).concat ["Work Order", work_order[:work_order_name]]
    worksheet.row(2).concat ["Return Date", work_order[:return_date]]
    worksheet.row(4).concat ["Contractor Name", work_order[:contractor]]

    create_table(work_order[:hearings], worksheet)
    workbook
  end

  def write_to_workbook(workbook, work_order_name)
    @file_name = "BVA-#{work_order_name}.xls"
    @file_path = TMP_FOLDER.join(@file_name)
    workbook.write(@file_path)
  end

  def create_table(hearings_data, worksheet)
    setup_worksheet_header(worksheet)
    hearings = fetch_hearings(hearings_data)
    populate_table_data(hearings, worksheet)
  end

  def setup_worksheet_header(worksheet)
    header_format = Spreadsheet::Format.new weight: :bold, border: :thin
    columns = ["DOCKET NUMBER", "FIRST NAME", "LAST NAME", "TYPES", "HEARING DATE", "RO", "VLJ", "APPEAL TYPE"]
    set_border_format(worksheet.row(6), header_format)
    worksheet.row(6).concat(columns)
  end

  def fetch_hearings(hearings_data)
    Hearing.includes(:appeal).where(id: hearings_data.pluck(:hearing_id))
  end

  def populate_table_data(hearings, worksheet)
    table_data = hearings.map do |hearing|
      format_hearing_data(hearing)
    end
    append_table_data_to_worksheet(table_data, worksheet)
  end

  def format_hearing_data(hearing)
    appeal = hearing.appeal
    hearing_date = format_hearing_date(appeal)
    [
      appeal.docket_number,
      hearing.appellant_first_name,
      hearing.appellant_last_name,
      appeal.type,
      hearing_date,
      hearing.regional_office.name,
      hearing.judge.full_name,
      appeal_type(appeal)
    ]
  end

  def format_hearing_date(appeal)
    if appeal.hearing_day_if_schedueled.present?
      appeal.hearing_day_if_schedueled.strftime("%m/%d/%Y")
    else
      ""
    end
  end

  def appeal_type(appeal)
    appeal.is_a?(LegacyAppeal) ? "Legacy" : "AMA"
  end

  def append_table_data_to_worksheet(table_data, worksheet)
    table_data.each_with_index do |row, index|
      worksheet.row(7 + index).replace(row)
    end
  end

  def set_border_format(row, row_format)
    (0..7).each do |col_index|
      row.set_format(col_index, row_format)
    end
  end

  def upload_to_s3
    begin
      S3Service.store_file(s3_location, @file_path, :filepath)
    rescue StandardError => error
      Rails.logger.error "Work Order File Job failed to upload to S3: #{error.message}"
      send_failure_notification
    end
  end

  def s3_location
    folder_name = (Rails.deploy_env == :prod) ? S3_BUCKET : "#{S3_BUCKET}-#{Rails.deploy_env}"
    "#{folder_name}/transcript_text/#{@file_name}"
  end

  def cleanup_tmp_file
    File.delete(@file_path) if File.exist?(@file_path)
  end

  def send_failure_notification
    WorkOrderFileIssuesMailer.send_notification
  end
end
