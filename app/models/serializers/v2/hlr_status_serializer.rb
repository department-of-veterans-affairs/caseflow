class HLRStatusSerializer < V2::AppealSerializer
	type :higher_level_review

	def id
      object.review_status_id
  	end

	attribute :linked_review_ids, key: :appeal_ids


	attribute :type do
	# this does not apply to HLR
	end

	attribute :location do
	# for HLR will always be aoj
	  "aoj"
	end

	attribute :aod do
	  # does not apply to HLR
	end

	attribute :docket do
    # doesn't apply to HLRs
  	end

	attribute :events do
	end
end
