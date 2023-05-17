# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubVerification::GithubVerificationController do
  fab!(:user) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }

  describe "#auth_callback" do
    before do
      stub_request(:post, "https://github.com/login/oauth/access_token").to_return(
        status: 200,
        body: "access_token=123",
      )

      stub_request(:get, "https://api.github.com/user").to_return(
        status: 200,
        body: "{\"login\": \"markvanlan\"}",
      )
    end

    it "errors when user isn't signed in" do
      get "/github-verification", params: { user_id: user.id, code: "abc" }

      expect(response.status).to eq(404)
    end

    it "errors when the current user can't edit the passed in user" do
      sign_in(other_user)

      get "/github-verification", params: { user_id: user.id, code: "abc" }

      expect(response.status).to eq(404)
    end

    it "errors even when an admin attempts to connect on a user's behalf" do
      sign_in(Fabricate(:admin))

      get "/github-verification", params: { user_id: user.id, code: "abc" }

      expect(response.status).to eq(404)
    end

    it "saves the users GitHub username in a custom field and redirects properly" do
      sign_in(user)

      get "/github-verification", params: { user_id: user.id, code: "abc" }

      expect(response).to redirect_to("http://test.localhost/u/#{user.username}/preferences/github")
      expect(user.custom_fields[GithubVerification::VERIFIED_GITHUB_USERNAME_FIELD]).to eq(
        "markvanlan",
      )
    end
  end

  describe "#clear_for_user" do
    it "errors when user isn't signed in" do
      delete "/github-verification/clear/#{user.id}.json"

      expect(response.status).to eq(404)
    end

    it "errors when the current user can't edit the passed in user" do
      sign_in(other_user)

      delete "/github-verification/clear/#{user.id}.json"

      expect(response.status).to eq(404)
    end

    it "clears the user's custom field" do
      sign_in(user)

      user.custom_fields[GithubVerification::VERIFIED_GITHUB_USERNAME_FIELD] = "markvanlan"
      user.save!

      delete "/github-verification/clear/#{user.id}.json"

      expect(response.status).to eq(200)
      expect(
        user.reload.custom_fields[GithubVerification::VERIFIED_GITHUB_USERNAME_FIELD],
      ).to be_nil
    end
  end
end