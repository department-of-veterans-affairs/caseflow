
class AutoAssigner
	BATCH_SIZE_PER_ATTORNEY = 5
	# todo: what is it
	CASE_STORAGE_LOCATION = 66

	def select_appeals_for_judge(judge)
		batch_size_per_judge = Judge.new(judge).attorneys.length * BATCH_SIZE_PER_ATTORNEY
		batch_size_for_all_judges = Attorney.list_all.length * BATCH_SIZE_PER_ATTORNEY

		number_of_outstanding_appeals = appeals_in_case_storage.length
		number_of_outstanding_priority_appeals = aod_and_cavc_appeals_in_case_storage.length

		# How far back we go in the docket depends on how many priority appeals there are.
		net_docket_range = [batch_size_for_all_judges - number_of_outstanding_priority_appeals, 0].max


		target_number_of_priority_appeals = ([number_of_outstanding_priority_appeals / batch_size_for_all_judges, 1].min * batch_size_per_judge).ceil
		
		rem = batch_size_per_judge

		priority_hearing_appeals = get_priority_appeals(judge, rem)

		rem -= len(priority_hearing_appeals)

		
	end

	def appeals_in_case_storage
		@appeals_in_case_storage ||= VACOLS::Case.where(bfcurloc: CASE_STORAGE_LOCATION)
	end

	def aod_and_cavc_appeals_in_case_storage
		@aod_and_cavc_appeals_in_case_storage ||= []
	end


end