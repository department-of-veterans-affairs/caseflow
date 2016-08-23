# Be sure to restart your server when you modify this file.
options = {
  key: '_caseflow-certification_session',
  secure: Rails.env.production?,
  expire_after: 2.weeks
}

Rails.application.config.session_store :cookie_store, options
