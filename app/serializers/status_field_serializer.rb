# frozen_string_literal: true

module StatusFieldSerializer do
	def status (object)
		StatusSerializer.new(object).serializable_hash[:data][:attributes]
	end
end
