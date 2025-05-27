import Component from "@ember/component";
import { LinkTo } from "@ember/routing";
import { classNames, tagName } from "@ember-decorators/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

@tagName("li")
@classNames(
  "user-preferences-nav-outlet",
  "user-nav__preferences-github-verification"
)
export default class UserNavPreferencesGithubVerification extends Component {
  <template>
    {{#if this.site.github_verification_enabled}}
      <LinkTo @route="preferences.github">
        {{icon "fab-github"}}
        <span>{{i18n "discourse_github_verification.github"}}</span>
      </LinkTo>
    {{/if}}
  </template>
}
