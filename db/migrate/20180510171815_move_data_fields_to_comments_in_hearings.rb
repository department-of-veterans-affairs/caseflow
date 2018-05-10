class MoveDataFieldsToCommentsInHearings < ActiveRecord::Migration[5.1]
  def change
    get_paragraph = ->(data) { data.blank? ? "<p></p><p></p><p></p>" : "<p>#{data}</p><p></p>" }

    Hearing.find_each do |hearing|
      hearings.summary = "<p><strong>Contentions</strong></p>#{get_paragraph.call(hearing.contentions)}"\
      "<p><strong>Evidence</strong></p> #{get_paragraph.call(hearing.evidence)}"\
      "<p><strong>Comments and special instructions to attorneys</strong></p>"\
      "#{get_paragraph.call(hearing.comments_for_attorney)}"

      hearing.save!
    end
  end
end
