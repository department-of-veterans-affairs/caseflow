class Admin::StyleguideController < ApplicationController
  before_action :verify_system_admin
  layout "styleguide"

  # def code_block( title = nil, lang = nil, &block )
  # output = capture( &block )
  # render partial: 'my_html_bits/code_block',
  #        locals:  {title: title, lang: lang, text: output }
  # end
end
