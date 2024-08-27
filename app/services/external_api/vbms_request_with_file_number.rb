# frozen_string_literal: true

##
# A request that requires the veteran's file number.
# The file number for a veteran can be a claim ID (8-digit) or the veteran's
# SSN (9-digit). This class wraps logic to retry the request for both the veteran's
# SSN and the claim ID (if different).
#

class ExternalApi::VbmsRequestWithFileNumber
  def initialize(file_number:, vbms_client: init_vbms_client, bgs_client: init_bgs_client)
    @file_number = file_number
    @vbms_client = vbms_client
    @bgs_client = bgs_client
  end

  def fetch; end

  protected

  attr_reader :file_number, :vbms_client, :bgs_client

  # Implement in subclass
  def do_request(_ssn_or_claim_number); end

  def request_with_retry
    DBService.release_db_connections

    begin
      # Try with veteran's file number first
      do_request(file_number)
    rescue VBMS::FilenumberDoesNotExist
      raise if bgs_claim_number_nil_or_same_as_veteran_file_number?

      # Fallback to BGS claim number
      do_request(bgs_claim_number)
    end
  end

  private

  def init_vbms_client
    VBMS::Client.from_env_vars(
      logger: VBMSCaseflowLogger.new,
      env_name: ENV["CONNECT_VBMS_ENV"],
      use_forward_proxy: FeatureToggle.enabled?(:vbms_forward_proxy)
    )
  end

  def init_bgs_client
    ExternalApi::BGSService.new
  end

  def bgs_claim_number_nil_or_same_as_veteran_file_number?
    bgs_claim_number.nil? || bgs_claim_number == file_number
  end

  def bgs_claim_number
    @bgs_claim_number ||= bgs_client.fetch_veteran_info(file_number)[:claim_number]
  end

  def verify_current_user_veteran_access(veteran)
    return if !FeatureToggle.enabled?(:check_user_sensitivity)

    current_user = RequestStore[:current_user]

    fail BGS::SensitivityLevelCheckFailure, "User does not have permission to access this information" unless
      SensitivityChecker.new(current_user).sensitivity_levels_compatible?(
        user: current_user,
        veteran: veteran
      )
  end
end
