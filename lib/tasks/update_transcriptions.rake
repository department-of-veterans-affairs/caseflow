# frozen_string_literal: true

namespace :db do
  desc "Update transcriptions table"
  task update_transcriptions: :environment do
    sql = File.read(Rails.root.join("db", "scripts", "update_transcriptions.sql"))
    ActiveRecord::Base.connection.execute(sql)
  end
end
