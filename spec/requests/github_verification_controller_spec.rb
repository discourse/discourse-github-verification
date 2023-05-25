# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubVerification::GithubVerificationController do
  fab!(:user) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }

  before do
    SiteSetting.discourse_github_verification_enabled = true
    SiteSetting.discourse_github_verification_client_id = "aa"
    SiteSetting.discourse_github_verification_client_secret = "bb"
  end

  shared_examples_for "improper_setup" do
    before { sign_in(user) }

    it "404s when `discourse_github_verification_enabled` is false" do
      SiteSetting.discourse_github_verification_enabled = false
      expect(make_request).to eq(404)
    end

    it "404s when `discourse_github_verification_client_id` is blank" do
      SiteSetting.discourse_github_verification_client_id = ""
      expect(make_request).to eq(404)
    end
    it "404s when `discourse_github_verification_client_secret` is blank" do
      SiteSetting.discourse_github_verification_client_secret = ""
      expect(make_request).to eq(404)
    end
  end

  describe "#auth_url" do
    it_behaves_like "improper_setup" do
      def make_request
        get "/github-verification/auth-url.json", params: { user_id: user.id }
      end
    end

    it "responds with the correct OAuth URL for GitHub" do
      sign_in(user)

      get "/github-verification/auth_url.json"

      expect(response.parsed_body["url"]).to start_with("https://github.com/login/oauth/authorize?")
      expect(response.parsed_body["url"]).to include("client_id=aa")
      expect(response.parsed_body["url"]).to include(
        "redirect_uri=http://test.localhost/github-verification",
      )
      expect(response.parsed_body["url"]).to include("user_id=#{user.id}")
      expect(response.parsed_body["url"]).to include("state=#{session[:github_verification_state]}")
    end
  end

  describe "#auth_callback" do
    it_behaves_like "improper_setup" do
      def make_request
        get "/github-verification", params: { user_id: user.id, code: "abc" }
      end
    end

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
    it_behaves_like "improper_setup" do
      def make_request
        delete "/github-verification/clear/#{user.id}.json"
      end
    end

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

  describe "#users" do
    it "serializes all the users with github account connected" do
      user.custom_fields[GithubVerification::VERIFIED_GITHUB_USERNAME_FIELD] = "markvanlan"
      user.save!

      third_user = Fabricate(:user)
      third_user.custom_fields[GithubVerification::VERIFIED_GITHUB_USERNAME_FIELD] = "test2"
      third_user.save!

      sign_in(Fabricate(:admin))

      get "/github-verification/users.json"

      expect(response.parsed_body.count).to eq(2)

      expect(response.parsed_body.detect { |row| row["id"] == user.id }["github_username"]).to eq(
        "markvanlan",
      )

      expect(
        response.parsed_body.detect { |row| row["id"] == third_user.id }["github_username"],
      ).to eq("test2")
    end
  end
end
