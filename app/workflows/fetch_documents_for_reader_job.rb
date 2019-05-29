# frozen_string_literal: true

class FetchDocumentsForReaderJob
  def initialize(user:, appeals:)
    @user = user
    @appeals = appeals
    @appeals_successful ||= 0
  end

  def process
    setup_debug_context
    appeals.each { |appeal| fetch_for_appeal(appeal) }
  rescue StandardError => error
    log_error
    # raising an exception here triggers a retry through shoryuken
    raise error
  end

  private

  attr_reader :user, :appeals

  def fetch_for_appeal(appeal)
    Raven.extra_context(appeal_id: appeal.id)
    appeal.document_fetcher.find_or_create_documents!
    @appeals_successful += 1
  rescue Caseflow::Error::EfolderError => error
    Rails.logger.error "Encountered #{error.class.name} when fetching documents for appeal #{appeal.id}"
  end

  def setup_debug_context
    RequestStore.store[:current_user] = user
    Raven.extra_context(application: "reader")
    Raven.user_context(
      email: user.email,
      css_id: user.css_id,
      station_id: user.station_id,
      regional_office: user.regional_office
    )
  end

  def log_info
    Rails.logger.info log_message
  end

  def log_error
    Rails.logger.error log_message("ERROR")
  end

  def log_message(status = "SUCCESS")
    "FetchDocumentsForReaderUserJob (user_id: #{user.id}) #{status}. " \
      "Retrieved #{@appeals_successful} / #{appeals.count} appeals"
  end
end
