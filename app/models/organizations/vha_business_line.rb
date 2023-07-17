# frozen_string_literal: true

class VhaBusinessLine < BusinessLine
  def self.singleton
    VhaBusinessLine.first || VhaBusinessLine.create(name: "Veterans Health Administration", url: "vha")
  end

  def included_tabs
    [:incomplete, :in_progress, :completed]
  end
end
