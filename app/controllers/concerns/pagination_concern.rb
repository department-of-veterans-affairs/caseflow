# frozen_string_literal: true

# shared code for controllers that pagination.
# requires methods:
#  * total_items
#  * allowed_params
#
module PaginationConcern
  extend ActiveSupport::Concern

  def pagination
    {
      page_size: page_size,
      current_page: current_page,
      total_pages: total_pages,
      total_items: total_items
    }
  end

  def total_pages
    total_pages = (total_items / page_size).to_i
    total_pages += 1 if total_items % page_size
    total_pages
  end

  def page_size
    50 # maybe make this optional param in future?
  end

  def current_page
    (allowed_params[:page] || 1).to_i
  end

  def page_start
    return 0 if current_page < 2

    (current_page - 1) * page_size
  end
end
