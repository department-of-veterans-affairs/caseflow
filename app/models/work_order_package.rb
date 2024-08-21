# frozen_string_literal: true

class WorkOrderPackage
  include ActiveModel::Model

  # Main method to display work order summary
  def self.display_wo_summary(task_number)
    wo_info = fetch_wo_info(task_number)
    wo_file_info = fetch_wo_file_info(task_number)
    wo_info.merge(wo_file_info)
  end

  def self.display_wo_contents(task_number)
    transcription = ::Transcription
      .includes(transcription_files: { hearing: :appeal })
      .find_by(task_number: task_number)

    return {} unless transcription

    transcription.transcription_files.map do |t|
      {
        docket_number: t.docket_number,
        case_details: t.case_details
      }
    end
  end

  def self.unassign_wo(task_number)
    update_transcription_package(task_number)
    update_transcription_info(task_number)
    get_banner_messages(task_number)
  end

  def self.get_banner_messages(task_number)
    transcription_package = TranscriptionPackage.find_by(task_number: task_number)
    return {} unless transcription_package

    contractor_name = transcription_package.contractor.name

    {
      hearing_message: COPY::HEARING_BANNER_MESSAGE,
      work_order_message: format(COPY::WORK_ORDER_BANNER_MESSAGE, contractor_name, contractor_name)
    }
  end

  def self.update_transcription_package(task_number)
    transcription_package = TranscriptionPackage.find_by(task_number: task_number)
    return false unless transcription_package

    if transcription_package
      transcription_package.update(
        status: "#{task_number} to cancelled",
        updated_by_id: current_user.id,
        updated_at: Time.zone.now
      )
    else
      Rails.logger.warn("TranscriptionPackage with task_number #{task_number} not found")
    end
  end

  def self.current_user
    User.first
  end

  def self.update_transcription_info(task_number)
    update_transcriptions(task_number)
    update_transcription_files(task_number)
  end

  def self.update_transcriptions(task_number)
    transcription_ids = fetch_transcription_ids(task_number)
    return if transcription_ids.empty?

    Transcription.where(id: transcription_ids).update_all(
      updated_by_id: current_user.id,
      deleted_at: Time.zone.now,
      updated_at: Time.zone.now
    )
  end

  def self.update_transcription_files(task_number)
    transcription_file_ids = fetch_transcription_file_ids(task_number)
    return if transcription_file_ids.empty?

    TranscriptionFile.where(id: transcription_file_ids).update_all(
      date_upload_box: nil,
      file_status: "Successful upload (AWS)",
      updated_by_id: current_user.id,
      updated_at: Time.zone.now
    )
  end

  def self.fetch_transcription_ids(task_number)
    Transcription.where(task_number: task_number).pluck(:id)
  end

  def self.fetch_transcription_file_ids(task_number)
    Transcription
      .where(task_number: task_number)
      .joins(:transcription_files)
      .pluck("transcription_files.id")
  end

  def self.fetch_wo_info(task_number)
    wo_info = TranscriptionPackage.joins(:contractor).select('transcription_packages.expected_return_date,
               transcription_packages.task_number,
               transcription_contractors.name')
      .find_by(task_number: task_number)

    return {} unless wo_info

    if wo_info
      {
        return_date: wo_info.expected_return_date,
        work_order: wo_info.task_number,
        contractor_name: wo_info.name
      }
    end
  end

  def self.fetch_wo_file_info(task_number)
    transcription = find_transcription_with_files(task_number)
    return {} unless transcription

    { wo_file_info: transcription.transcription_files.map { |file| build_file_info(file) } }
  end

  def self.find_transcription_with_files(task_number)
    ::Transcription.includes(
      transcription_files: { hearing: [:hearing_day, :appeal, :judge] }
    ).find_by(task_number: task_number)
  end

  def self.build_file_info(file)
    {
      docket_number: file.docket_number,
      case_type: file.hearing_type,
      hearing_date: file.hearing.hearing_day&.scheduled_for,
      first_name: file.hearing&.appellant_first_name,
      last_name: file.hearing&.appellant_last_name,
      judge_name: file.hearing&.judge&.full_name,
      regional_office: file.hearing&.closest_regional_office_city,
      types: build_types(file.hearing)
    }
  end

  def self.build_types(hearing)
    [
      hearing&.original_appeal_type,
      hearing&.mo_appeal_type
    ].compact.join(", ")
  end
end
