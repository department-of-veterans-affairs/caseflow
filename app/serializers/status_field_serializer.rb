# frozen_string_literal: true

module StatusFieldSerializer
	def status (object)
		StatusSerializer.new(object).serializable_hash[:data][:attributes]
	end
end
