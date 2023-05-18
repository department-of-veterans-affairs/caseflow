# frozen_string_literal: true

module QueueHelpers
  def mtv_const
    Constants.MOTION_TO_VACATE
  end

  def disposition_text
    mtv_const.DISPOSITION_TEXT.to_h
  end

  def recommendation_text
    mtv_const.DISPOSITION_RECOMMENDATIONS.to_h
  end

  def vacate_types
    mtv_const.VACATE_TYPE_OPTIONS.map { |opt| [opt["value"].to_sym, opt["displayText"]] }.to_h
  end

  def format_mtv_attorney_instructions(notes:, disposition:, hyperlinks: [])
    parts = [recommendation_text[disposition.to_sym], notes]

    hyperlinks.each do |item|
      next if item[:link].empty?

      parts += [
        "\nHere is the hyperlink to the #{format(item[:type], disposition_text[disposition.to_sym])}:\n#{item[:link]}"
      ]
    end

    parts.join("\n")
  end

  def format_mtv_judge_instructions(notes:, disposition:, vacate_type: nil, hyperlink: nil)
    parts = ["**Motion To Vacate:**  \n#{(disposition_text[disposition])}\n"]

    case disposition
    when "granted", "partially_granted"
      parts += ["**Type:**  "]
      parts +=["#{vacate_types[vacate_type.to_sym]}\n"]
      if !notes.empty?
        parts += ["**Detail:**  "]
        parts += ["#{notes}\n"]
      end
    when "denied", "dismissed"
      if !notes.empty?
        parts += ["**Detail:**  "]
        parts += ["#{notes}\n"]
      end
      if hyperlink.present?
        parts += ["**Hyperlink**  "]
        parts += ["#{hyperlink}\n"]
      end
    end

    parts.join("\n")
  end
end
