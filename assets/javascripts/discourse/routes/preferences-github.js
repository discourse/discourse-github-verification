import RestrictedUserRoute from "discourse/routes/restricted-user";
import { defaultHomepage } from "discourse/lib/utilities";

export default class PreferencesChatRoute extends RestrictedUserRoute {
  beforeModel() {
    if (!this.site.github_verification_enabled) {
      return this.router.transitionTo(`discovery.${defaultHomepage()}`);
    }
  }
}
