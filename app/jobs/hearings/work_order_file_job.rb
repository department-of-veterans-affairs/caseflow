# frozen_string_literal: true

class Hearings::WorkOrderFileJob < CaseflowJob
  queue_with_priority :low_priority

  def perform(work_order)
    work_book = create_spreadsheet(work_order)
    file_location(work_book, work_order[:work_order_name])
    # upload to s3
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

  def file_location(workbook, work_order_name)
    file_name = "BVA-#{work_order_name}.xls"
    file_path = File.join(Rails.root, "tmp", file_name)
    workbook.write(file_path)
  end

  def create_table(hearings_data, worksheet)
    header_format = Spreadsheet::Format.new weight: :bold, border: :thin
    border_format = Spreadsheet::Format.new border: :thin

    columns = [
      "DOCKET NUMBER",
      "FIRST NAME",
      "LAST NAME",
      "TYPES",
      "HEARING DATE",
      "RO",
      "VLJ",
      "APPEAL TYPE"
    ]
    set_border_format(worksheet.row(6), header_format)
    worksheet.row(6).concat columns
    hearings = Hearing.includes(:appeal).where(id: hearings_data.pluck(:hearing_id))

    table_data = []
    hearings.each do |hearing|
      appeal = hearing.appeal

      hearing_date = if appeal.hearing_day_if_schedueled.present?
                       appeal.hearing_day_if_schedueled.strftime("%m/%d/%Y")
                     else
                       ""
                     end

      table_data << [
        appeal.docket_number,
        hearing.appellant_first_name,
        hearing.appellant_last_name,
        appeal.type,
        hearing_date,
        hearing.regional_office.name,
        hearing.judge.full_name,
        appeal.is_a?(LegacyAppeal) ? "Legacy" : "AMA"
      ]
    end

    table_data.each_with_index do |row_data, row_index|
      set_border_format(worksheet.row(row_index + 7), border_format)
      worksheet.row(row_index + 7).concat row_data
    end
  end

  def set_border_format(row, row_format)
    (0..7).each do |col_index|
      row.set_format(col_index, row_format)
    end
  end
end
