Sidekiq.configure_server do |config|
  config.redis = { url: Rails.application.secrets.redis_url_sidekiq }

  schedule_file = Rails.root + "config/sidekiq_cron.yml"
  if File.exists?(schedule_file) && Sidekiq.server?
    jobs = YAML.load_file(schedule_file)
    active_jobs = jobs.reject { |k, v| v["disabled"] }

    Sidekiq::Cron::Job.load_from_hash! active_jobs
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: Rails.application.secrets.redis_url_sidekiq }
end
