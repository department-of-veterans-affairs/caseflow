# frozen_string_literal: true

module QueueHelpers
  def format_judge_instructions(notes:, disposition:, vacate_type: nil, hyperlink: nil)
    parts = ["I am proceeding with a #{DISPOSITION_TEXT[disposition.to_sym]}."]

    parts += case disposition
             when "granted"
               ["This will be a #{VACATE_TYPE_TEXT[vacate_type.to_sym]}", notes]
             else
               [notes, "\nHere is the hyperlink to the signed denial document", hyperlink]
             end

    parts.join("\n")
  end
end
