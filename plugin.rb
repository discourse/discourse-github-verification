# frozen_string_literal: true

# name: discourse-github-verification
# about: Verifies that a user owns a given GitHub account
# version: 0.0.1
# authors: Discourse (markvanlan)
# url: https://github.com/discourse/discourse-github-verification
# required_version: 2.7.0

enabled_site_setting :discourse_github_verification_enabled

register_asset "stylesheets/github-verification.scss"

module ::GithubVerification
  PLUGIN_NAME = "discourse-github-verification"
  VERIFIED_GITHUB_USERNAME_FIELD = "github_verified_username"
end

require_relative "lib/github_verification/engine"

after_initialize do
  allow_public_user_custom_field GithubVerification::VERIFIED_GITHUB_USERNAME_FIELD

  add_to_serializer(
    :site,
    :github_verification_enabled,
    include_condition: -> do
      SiteSetting.discourse_github_verification_enabled &&
        SiteSetting.discourse_github_verification_client_id.present? &&
        SiteSetting.discourse_github_verification_client_secret.present?
    end,
  ) { true }
end
