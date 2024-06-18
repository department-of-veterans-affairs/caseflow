# frozen_string_literal: true

VANotifyService = if ApplicationController.dependencies_faked? || ENV["FAKE_VA_NOTIFY_SERVICE"]
                    Fakes::VANotifyService
                  else
                    ExternalApi::VANotifyService
                  end
