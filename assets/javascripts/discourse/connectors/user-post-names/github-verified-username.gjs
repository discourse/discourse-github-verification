import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import { and } from "truth-helpers";
import GithubUserLink from "../../components/github-user-link";

@tagName("div")
@classNames("user-post-names-outlet", "github-verified-username")
export default class GithubVerifiedUsername extends Component {
  <template>
    {{#if
      (and
        this.site.github_verification_enabled
        this.model.custom_fields.github_verified_username
      )
    }}
      <GithubUserLink
        @username={{this.model.custom_fields.github_verified_username}}
      />
    {{/if}}
  </template>
}
