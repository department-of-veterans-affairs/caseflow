# frozen_string_literal: true

# Configuration option to change Timezone at a per test basis via metadata attributes
RSpec.configure do |config|
  config.around :example, :tz do |example|
    Time.use_zone(example.metadata[:tz]) { example.run }
  end
end
