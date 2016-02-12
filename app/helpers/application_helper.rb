# frozen_string_literal: true
module ApplicationHelper
  MISSING_ICON = <<-HTML.freeze
    <svg width="55" height="55" class="cf-icon-missing"
    xmlns="http://www.w3.org/2000/svg" viewBox="0 0 55 55">
      <title>missing icon</title>
      <path d="M52.6 46.9l-6 6c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-13-13-13
      13c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-6-6c-.8-.8-1.2-1.9-1.2-3s.4-2.2
      1.2-3l13-13-13-13c-.8-.8-1.2-1.9-1.2-3s.4-2.2 1.2-3l6-6c.8-.8 1.9-1.2
      3-1.2s2.2.4 3 1.2l13 13 13-13c.8-.8 1.9-1.2 3-1.2s2.2.4 3 1.2l6 6c.8.8
      1.2 1.9 1.2 3s-.4 2.2-1.2 3l-13 13 13 13c.8.8 1.2 1.9 1.2 3s-.4 2.2-1.2 3z"/>
    </svg>
  HTML

  FOUND_ICON = <<-HTML.freeze
    <svg width="55" height="55" class="cf-icon-found"
    xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 50">
      <title>found</title>
      <path d="M57 13.3L29.9 41.7 24.8 47c-.7.7-1.6 1.1-2.5 1.1-.9 0-1.9-.4-2.5-1.1l-5.1-5.3L1
       27.5c-.7-.7-1-1.7-1-2.7s.4-2 1-2.7l5.1-5.3c.7-.7 1.6-1.1 2.5-1.1.9 0 1.9.4 2.5 1.1l11
       11.6L46.8 2.7c.7-.7 1.6-1.1 2.5-1.1.9 0 1.9.4 2.5 1.1L57 8c.7.7 1 1.7 1 2.7 0 1-.4 1.9-1
       2.6z"/>
    </svg>
  HTML

  APPEAL_ICON = <<-HTML.freeze
    <svg width="16" height="16" class="cf-icon-appeal-id"
    xmlns="http://www.w3.org/2000/svg" viewBox="0 0 21 21">
    <title>appeal</title>
    <path d="M13.346 2.578h-2.664v-1.29C10.682.585 10.08 0 9.35 0H6.66c-.728 0-1.33.584-1.33
    1.29v1.288H2.663v2.577h10.682V2.578zm-4.02 0H6.66v-1.29h2.665v1.29zm6.685
    3.89V3.234a.665.665 0 0
    0-.678-.656H14v1.29h.68v2.576H6.66v9.046H1.333V3.867h.68v-1.29H.678a.665.665 0 0
    0-.68.657v12.913c0 .365.302.656.68.656h6.006v3.867h9.35l3.996-3.867V6.468h-4.02zm0
    12.378v-2.043h2.112l-2.11 2.043zm2.665-3.356H14.68v3.867H7.992v-11.6h10.682v7.733z"
    fill="#5B616B" fill-rule="evenodd"/></svg>
  HTML

  def svg_icon(name)
    {
      missing: MISSING_ICON,
      found: FOUND_ICON,
      appeal: APPEAL_ICON
    }[name].html_safe
  end
end
