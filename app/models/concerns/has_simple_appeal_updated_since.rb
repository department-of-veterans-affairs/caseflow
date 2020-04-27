# frozen_string_literal: true

module HasSimpleAppealUpdatedSince
  extend ActiveSupport::Concern

  included do
    scope :updated_since_for_appeals, lambda { |since|
      select(:appeal_id).where("#{table_name}.updated_at >= ?", since)
    }
  end
end
