import { defaultHomepage } from "discourse/lib/utilities";
import RestrictedUserRoute from "discourse/routes/restricted-user";

export default class PreferencesChatRoute extends RestrictedUserRoute {
  beforeModel() {
    if (!this.site.github_verification_enabled) {
      return this.router.transitionTo(`discovery.${defaultHomepage()}`);
    }
  }
}
