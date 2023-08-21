# frozen_string_literal: true

# Load any custom scalar types
Dir[Rails.root.join("app", "graphql", "types", "custom_scalars", "{**}")].sort.each do |path|
  require path
end
