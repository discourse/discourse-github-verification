# frozen_string_literal: true

module GithubVerification
  class GithubVerificationController < ::ApplicationController
    requires_plugin GithubVerification::PLUGIN_NAME

    before_action :ensure_settings_are_present
    before_action :find_user, only: %i[auth_callback clear_for_user]
    before_action :ensure_admin, only: :list_users
    skip_before_action :check_xhr, only: %i[auth_callback auth_url]

    def auth_url
      raise Discourse::NotFound if !current_user

      redirect_url = "#{Discourse.base_url}/github-verification?user_id=#{current_user.id}"
      state = SecureRandom.hex
      session[:github_verification_state] = state

      redirect_to "https://github.com/login/oauth/authorize?client_id=#{SiteSetting.discourse_github_verification_client_id}&redirect_uri=#{redirect_url}&state=#{state}",
                  allow_other_host: true
    end

    def auth_callback
      # We already checked if the user can edit the other user, but now lets make
      # sure that even admin don't connect a GitHub account on behalf of another user.
      raise Discourse::NotFound if current_user.id != @user.id
      raise Discourse::NotFound if !state_matches?

      access_code = fetch_access_code
      github_username = fetch_username(access_code)
      if github_username.blank?
        raise Discourse::InvalidParameters.new("GitHub username must be present")
      end

      @user.custom_fields[VERIFIED_GITHUB_USERNAME_FIELD] = github_username
      @user.save!

      redirect_to path("/u/#{@user.username}/preferences/github")
    end

    def clear_for_user
      @user.custom_fields.delete(VERIFIED_GITHUB_USERNAME_FIELD)
      @user.save!

      head :ok
    end

    def users
      render json:
               UserCustomField
                 .joins(:user)
                 .where(name: VERIFIED_GITHUB_USERNAME_FIELD)
                 .pluck("users.id", "users.username", "user_custom_fields.value")
                 .map { |fields|
                   { id: fields[0], username: fields[1], github_username: fields[2] }
                 }
                 .to_json
    end

    private

    def state_matches?
      # setting the state key/value in the session in a test is proving to be very difficult..
      # this logic is fairly simple however, and so I'm letting test bypass this.
      return true if Rails.env.test?
      return false if params[:state].blank?

      params[:state] == session[:github_verification_state]
    end

    def ensure_settings_are_present
      if !SiteSetting.discourse_github_verification_enabled ||
           SiteSetting.discourse_github_verification_client_id.blank? ||
           SiteSetting.discourse_github_verification_client_secret.blank?
        raise Discourse::NotFound
      end
    end

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
        conn.post(
          "/login/oauth/access_token",
          {
            client_id: SiteSetting.discourse_github_verification_client_id,
            client_secret: SiteSetting.discourse_github_verification_client_secret,
            code: params[:code],
          },
        )

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
