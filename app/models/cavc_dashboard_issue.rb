# frozen_string_literal: true

class CavcDashboardIssue < CaseflowRecord
	include CreatedAndUpdatedByUserConcern
	
	belongs_to :cavc_remand

	validates :cavc_remand, presence: true

end
