# frozen_string_literal: true

module GithubVerification
  class GithubVerificationController < ::ApplicationController
    requires_plugin GithubVerification::PLUGIN_NAME

    before_action :find_user
    skip_before_action :check_xhr, only: :auth_callback

    def auth_callback
      # We already checked if the user can edit the other user, but now lets make
      # sure that even admin don't connect a GitHub account on behalf of another user.
      raise Discourse::NotFound if current_user.id != @user.id

      access_code = fetch_access_code
      github_username = fetch_username(access_code)
      if github_username.blank?
        raise Discourse::InvalidParameters.new("Github username must be present")
      end

      @user.custom_fields[VERIFIED_GITHUB_USERNAME_FIELD] = github_username
      @user.save!

      redirect_to "/u/#{@user.username}/preferences/github"
    end

    def clear_for_user
      @user.custom_fields.delete(VERIFIED_GITHUB_USERNAME_FIELD)
      @user.save!

      head :ok
    end

    private

    def find_user
      @user = User.find_by(id: params[:user_id])
      raise Discourse::NotFound if @user.blank? || !guardian.can_edit_user?(@user)
    end

    def fetch_access_code
      conn =
        Faraday.new(url: "https://github.com") do |t|
          t.request :json
          t.response :json
        end

      response =
        conn.post("/login/oauth/access_token") do |req|
          req.body = {
            client_id: SiteSetting.discourse_github_verification_client_id,
            client_secret: SiteSetting.discourse_github_verification_client_secret,
            code: params[:code],
          }.to_json
        end

      response_body = Rack::Utils.parse_nested_query(response.body)
      response_body["access_token"]
    end

    def fetch_username(access_token)
      conn =
        Faraday.new(
          url: "https://api.github.com",
          headers: {
            "Authorization" => "Bearer #{access_token}",
            "Content-Type" => "application/json",
          },
        )

      response = conn.get("/user")
      JSON.parse(response.body)["login"]
    end
  end
end
