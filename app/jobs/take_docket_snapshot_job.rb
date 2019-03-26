# frozen_string_literal: true

class TakeDocketSnapshotJob < ApplicationJob
  queue_as :low_priority
  application_attr :api

  def perform
    DocketSnapshot.create
  end
end
