# frozen_string_literal: true

require_relative "../../helpers/appellant_change.rb"

namespace :remediations do
  desc "Changes the Claimant on the appeal"
  task :appellant_change,
       [:appeal_uuid, :claimant_participant_id, :claimant_type, :claimant_payee_code] => [:environment] do |_, args|
    AppellantChange.run_appellant_change(
      appeal_uuid: args.appeal_uuid,
      claimant_participant_id: args.claimant_participant_id,
      claimant_type: args.claimant_type,
      claimant_payee_code: args.claimant_payee_code
    )
  end
end
