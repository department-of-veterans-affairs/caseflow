# frozen_string_literal: true

class StyleguideController < ApplicationController
  skip_before_action :verify_authentication
end
