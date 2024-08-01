# frozen_string_literal: true

VeteranFileFetcher = ExternalApi::VeteranFileFetcher
  .new(use_canned_api_responses: ApplicationController.dependencies_faked?, logger: Rails.logger)

VeteranFileUpdater = ExternalApi::VeteranFileUpdater
  .new(use_canned_api_responses: ApplicationController.dependencies_faked?, logger: Rails.logger)

VeteranFileUploader = ExternalApi::VeteranFileUploader
  .new(use_canned_api_responses: ApplicationController.dependencies_faked?, logger: Rails.logger)
