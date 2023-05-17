# frozen_string_literal: true

# name: discourse-github-verification
# about: TODO
# version: 0.0.1
# authors: Discourse (markvanlan)
# url: TODO
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
end
