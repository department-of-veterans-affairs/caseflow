# frozen_string_literal: true

RSpec.configure do |config|
  if Bullet.enable?
    config.before(:each) do
      Bullet.start_request
    end

    config.after(:each) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end

    Bullet.add_whitelist type: :n_plus_one_query, class_name: "HearingTask", association: :hearing_task_association
  end
end
