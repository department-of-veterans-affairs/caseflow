# frozen_string_literal: true

class TaskEvent
  include ActiveModel::Model

  attr_accessor :version

  def diff
    # see https://github.com/paper-trail-gem/paper_trail#3c-diffing-versions
    version.changeset
  end

  def who
    User.find(version.whodunnit)
  end

  delegate :created_at, to: :version

  def summary
    "[#{created_at}] [#{who.css_id}]\n#{diff.pretty_inspect}"
  end
end
