# frozen_string_literal: true

module QueueHelpers
  def mtv_const
    Constants.MOTION_TO_VACATE
  end

  def disposition_text
    mtv_const.DISPOSITION_TEXT.to_h
  end

  def vacate_types
    mtv_const.VACATE_TYPE_OPTIONS.map { |opt| [opt["value"].to_sym, opt["displayText"]] }.to_h
  end

  def format_mtv_attorney_instructions(notes:, disposition:, hyperlinks: nil)
    parts = ["I recommend #{disposition_text[disposition.to_sym]}.", notes]

    if hyperlinks.size
      parts += ["\nDocument Links:"]

      denial_dismissal_draft = hyperlinks.shift
      if ["denied", "dismissed"].include?(disposition)
        parts += ["\nHere is the hyperlink to the #{disposition_text[disposition.to_sym]} draft:\n#{denial_dismissal_draft[:link]}"] 
      end

      motion_draft = hyperlinks.shift
      parts += ["\nHere is the hyperlink to the draft of the motion:\n#{motion_draft[:link]}"]

      hyperlinks.each do |item|
        parts += ["\nHere is the hyperlink to the #{item[:type]}:\n#{item[:link]}"]
      end
    end

    parts.join("\n")
  end

  def format_mtv_judge_instructions(notes:, disposition:, vacate_type: nil, hyperlink: nil)
    parts = ["I am proceeding with a #{disposition_text[disposition.to_sym]}."]

    parts += case disposition
             when "granted", "partial"
               ["This will be a #{vacate_types[vacate_type.to_sym]}", notes]
             else
               [notes, "\nHere is the hyperlink to the signed denial document", hyperlink]
             end

    parts.join("\n")
  end
end
