# frozen_string_literal: true

##
# Helpers for use inside a template for virtual hearings
# emails and calendar invites.

module VirtualHearings::AppellantNameHelper
  def formatted_appellant_name(appeal)
    return appeal.appellant_fullname_readable || "the appellant" if appeal.appellant_is_not_veteran

    appeal&.veteran&.name&.formatted(:readable_fi_last_formatted) || "the veteran"
  end

  def appellant_or_veteran(appeal)
    appeal.appellant_is_not_veteran ? "Appellant" : "Veteran"
  end

  # prepends a or an to param
  # taken from https://stackoverflow.com/questions/5381738/rails-article-helper-a-or-an
  def articlerize(params_word)
    %w[a e i o u].include?(params_word[0].downcase) ? "an #{params_word}" : "a #{params_word}"
  end
end
