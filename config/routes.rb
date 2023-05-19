# frozen_string_literal: true

GithubVerification::Engine.routes.draw do
  get "/" => "github_verification#auth_callback"
  delete "/clear/:user_id" => "github_verification#clear_for_user"
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
