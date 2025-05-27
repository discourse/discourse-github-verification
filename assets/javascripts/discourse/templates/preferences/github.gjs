import RouteTemplate from "ember-route-template";
import { eq } from "truth-helpers";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";
import GithubUserLink from "../../components/github-user-link";

export default RouteTemplate(
  <template>
    <div class="control-group github-username">
      <label class="control-label" for="edit-github-username">
        {{i18n "discourse_github_verification.username"}}
      </label>
      <div class="controls">
        {{#if @controller.githubUsername}}
          <div class="github-username-control-wrapper">
            <GithubUserLink @username={{@controller.githubUsername}} />
            <DButton
              @action={{@controller.clear}}
              @icon="trash-can"
              @title="discourse_github_verification.clear"
              class="btn-secondary clear-github-verification-btn"
            />
          </div>
          <p class="instructions">
            {{i18n "discourse_github_verification.instructions.clear"}}
          </p>
        {{else}}
          {{#if (eq @controller.currentUser.id @controller.model.id)}}
            <DButton
              @action={{@controller.login}}
              @icon="fab-github"
              @label="discourse_github_verification.connect"
              class="btn-primary github-verification-btn"
            />
            <p class="instructions">
              {{i18n "discourse_github_verification.instructions.connect"}}
            </p>
          {{else}}
            <p>
              {{i18n
                "discourse_github_verification.instructions.cannot_connect_for_others"
              }}
            </p>
          {{/if}}
        {{/if}}
      </div>
    </div>
  </template>
);
