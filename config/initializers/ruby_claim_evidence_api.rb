# frozen_string_literal: true

VeteranFileFetcher = ExternalApi::VeteranFileFetcher
  .new(use_canned_api_responses: ApplicationController.dependencies_faked?)
