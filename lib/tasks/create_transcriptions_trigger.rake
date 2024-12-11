# frozen_string_literal: true

namespace :db do
  desc "Create transcriptions trigger"
  task create_transcriptions_trigger: :environment do
    sql = File.read(Rails.root.join("db", "scripts", "create_transcriptions_trigger.sql"))
    ActiveRecord::Base.connection.execute(sql)
  end
end
