class PrepareEstablishClaimTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    @prepared_count = EstablishClaim.unprepared.inject(0) do |count, task|
      count + (task.prepare_with_decision! == :success ? 1 : 0)
    end

    Rails.logger.info "Successfully prepared #{@prepared_count} tasks"
  end
end
