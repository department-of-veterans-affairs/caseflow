# frozen_string_literal: true

module MembershipRequestHelper
  def vha_predocket_rejection_header_content(requesting_org_name, has_vha_access, pending_requests)
    additional_context = case [has_vha_access, pending_requests.present?]
                         when [true, false]
                           ". Your existing group membership did not change."
                         when [false, false]
                           " and the VHA pages in general."
                         else
                           "."
                         end
    content_string = "At this time, we have denied your request for access to #{requesting_org_name} pages in Caseflow"
    extra_message_content = "If you are in need of access to VHA pages without #{requesting_org_name} specific pages,"\
      " please make a new request for VHA access by going to "\
      " #{link_to('http://www.appeals.cf.ds.va.gov/vha=help', 'http://www.appeals.cf.ds.va.gov/vha=help')} "\
      "and selecting only the VHA checkbox when re-submitting the form."
    additional_message = (!has_vha_access && pending_requests.blank?) ? extra_message_content.html_safe : nil

    html = content_tag(:p, "#{content_string}#{additional_context}")
    html += content_tag(:p, additional_message) if additional_message
    html
  end
end
