class RolledOverText
  include ActionView::Helpers::TextHelper

  def initialize(raw, max_lines, opts = {})
    @initial_append = " " + (opts[:initial_append] || "(see continued remarks page 2)").strip
    @continued_prepend = "\n \n" + (opts[:continued_prepend] || "Continued:").strip + "\n"
    @max_lines = max_lines
    @max_line_length = opts[:max_line_length] || 101

    parsed = parse_to_array(raw || "")
    @initial = parsed[0]
    @continued = parsed[1]
  end

  attr_reader :initial, :continued

  def rollover?
    !@continued.nil?
  end

  def empty?
    !rollover? && initial.empty?
  end

  private

  def wrap(raw)
    word_wrap(raw, line_width: @max_line_length)
  end

  def rollover_wrapped(wrapped, raw)
    lines = wrapped.split("\n")
    last_line = lines[@max_lines - 1]
    last_line_cutoff_index = @max_line_length - @initial_append.length

    # find last space
    last_line_cutoff_index = last_line.rindex(" ", last_line_cutoff_index) || last_line.length

    # transalte to position in raw
    num_separators = @max_lines - 1
    length_up_to_last_line = lines.slice(0, @max_lines - 1).reduce(0) do |sum, line|
      sum + line.length
    end

    cutoff_index_in_raw = length_up_to_last_line + last_line_cutoff_index + num_separators

    initial = raw[0, cutoff_index_in_raw] + @initial_append
    continued = @continued_prepend + raw[cutoff_index_in_raw + 1, raw.length]

    [initial, continued]
  end

  def rollover_breaking(raw, maxlength)
    initial = "#{raw[0...maxlength]}#{@initial_append}"
    continued = @continued_prepend + raw[maxlength...raw.length]
    [initial, continued]
  end

  def parse_to_array(raw)
    wrapped = wrap(raw)
    num_lines = wrapped.count("\n") + 1
    do_rollover = num_lines > @max_lines
    breaking_maxlength = @max_lines * @max_line_length

    if do_rollover
      rollover_wrapped(wrapped, raw)
    elsif raw.length > breaking_maxlength
      rollover_breaking(raw, breaking_maxlength - @initial_append.length)
    else
      # don't process, will be wrapped in PDF
      [raw, nil]
    end
  end
end
