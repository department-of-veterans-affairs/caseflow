# frozen_string_literal: true

SearchQueryService::ApiResponse = Struct.new(:id, :type, :attributes, keyword_init: true)
