class ConvertHearingSummaryNewLines < ActiveRecord::Migration[5.1]
  def change
    Hearing.where("length(summary) > 0").find_each do |hearing|
      hearing.summary = hearing.summary.gsub(/\\n/, "</br>")
      hearing.save!
    end
  end
end
