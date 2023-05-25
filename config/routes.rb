# frozen_string_literal: true

GithubVerification::Engine.routes.draw do
  get "/" => "github_verification#auth_callback" # OAuth redirects back to here
  get "/auth_url" => "github_verification#auth_url" # Ember app hits this endpoints to get URL to redirect to
  delete "/clear/:user_id" => "github_verification#clear_for_user" # Clear custom field for user
  get "/users" => "github_verification#users", :constraints => AdminConstraint.new
end
Discourse::Application.routes.draw do
  mount ::GithubVerification::Engine, at: "/github-verification"
end

Discourse::Application.routes.append do
  get "u/:username/preferences/github" => "users#preferences",
      :constraints => {
        username: RouteFormat.username,
      },
      :as => :user_preferences_github
end
