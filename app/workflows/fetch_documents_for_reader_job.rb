# frozen_string_literal: true

class FetchDocumentsForReaderJob
  # in order to save variables that are passed in, they need to have instances
  # to be initialized. User and Appeal symbols are initialized and saved
  # appeals successful instance created
  def initialize(user:, appeals:)
    @user = user
    @appeals = appeals
    @appeals_successful ||= 0
  end

  # once appeals and user instances are saved into variables process method is ran
  def process
    # private method that setups the debug context on line 47
    # arguments passed into this method is the user object
    # returns user_context object{email, css id, station id and regional office,
    # application: "reader" }
    setup_debug_context
    # loop through appeals object to fetch each appeal with
    # private method fetch_for_appeal line 43
    # input: argument passed in is appeal
    # output: documents, appeals_sucessful variable. if there is an error returns error
    # exception string
    appeals.each { |appeal| fetch_for_appeal(appeal) }
    # private method on line 89
    # returns logger info message status of success with user.id and successful appeals
    # retrieved along with the total count of appeals in a string
    log_info
    # returns log_message of error and then raise the error
  rescue VBMS::FilenumberDoesNotExist => error
    # there is nothing actionable here, since it reflects data changes on the VBMS side.
    # we do not want to retry since it will never work.
    Rails.logger.error error
    # private method on line 89
    # returns log_message("error")
    log_error
  rescue StandardError => error
    Rails.logger.error error
    # private method on line 89
    # returns log_message("error")
    log_error
    # raising an exception here triggers a retry through shoryuken
    raise error
  end

  private

  attr_reader :user, :appeals

  # arguments input is appeal
  # returns document and add 1  to appeals_successful variable
  # there is an exception handler that logs any possible errors
  def fetch_for_appeal(appeal)
    # binds extra content to current context using
    Raven.extra_context(appeal_id: appeal.id)
    # this method is defined and commented on line 21 in class DocumentFetcher
    # parameters input is appeal_id
    # returns documents then updates and/or create them, in the db
    appeal.document_fetcher.find_or_create_documents!
    # updates appeals_successful variable after complete loop
    @appeals_successful += 1
    # rescue is an exception handler to catch any errors  with a message
    # of the error the class name and  documents for appeal.id
  rescue Caseflow::Error::EfolderError => error
    Rails.logger.error "Encountered #{error.class.name} when fetching documents for appeal #{appeal.id}"
  end

  # setups the debug context
  # arguments passed into this method is the user object
  # returns user_context which has extra_context
  def setup_debug_context
    # Request Store allows you to use a variable  globally
    # :current_user is now available globally within the method
    RequestStore.store[:current_user] = user
    # Bind extra context. Merges with existing context (if any)
    # bind application: "reader" to the current context
    Raven.extra_context(application: "reader")
    # Bind user context. Merges with existing context (if any).
    # bind email, css_id, station_id and regional_office symbols to proper object.
    Raven.user_context(
      email: user.email,
      css_id: user.css_id,
      station_id: user.station_id,
      regional_office: user.regional_office
    )
  end

  def log_info
    # private method on line 98
    # returns string with user_id status and Retrieved @appeals_successful and
    # appeals count
    Rails.logger.info log_message
  end

  def log_error
    Rails.logger.error log_message("ERROR")
  end

  # input user.id, status, appeals_succesful and appeals.count
  # returns string
  def log_message(status = "SUCCESS")
    "FetchDocumentsForReaderUserJob (user_id: #{user.id}) #{status}. " \
      "Retrieved #{@appeals_successful} / #{appeals.count} appeals"
  end
end
