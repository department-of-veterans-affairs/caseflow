# frozen_string_literal: true

# bundle exec rails runner scripts/add_cavc_selection_bases.rb

Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }
Seeds::CavcSelectionBasisData.new.seed!
