# frozen_string_literal: true

# bundle exec rails runner scripts/run_seed_data_file.rb db/seeds/_______.rb

Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }

if ARGV[0].blank?
  puts "No seeding class was provided. Please provide a class name or file name from db/seeds/"
end

seed_class = "Seeds::#{ARGV[0].gsub('db/seeds/', '').gsub('.rb', '').camelize}"&.constantize

if seed_class.present?
  seed_class.new.send("seed!")
end
