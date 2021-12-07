# frozen_string_literal: true

class DocumentView < CaseflowRecord
  belongs_to :document
  belongs_to :user
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: document_views
#
#  id              :integer          not null, primary key
#  first_viewed_at :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  document_id     :integer          not null, indexed => [user_id]
#  user_id         :integer          not null, indexed => [document_id], indexed
#
# Foreign Keys
#
#  fk_rails_a4855043ec  (user_id => users.id)
#
