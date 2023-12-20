# frozen_string_literal: true

module HasAppealUpdatedSince
  extend ActiveSupport::Concern

  included do
    scope :updated_since_for_appeals, lambda { |since|
      select(:appeal_id)
        .where("#{table_name}.updated_at >= ?", since)
        .where("#{table_name}.appeal_type='Appeal'")
    }
  end
end
