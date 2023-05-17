import RestrictedUserRoute from "discourse/routes/restricted-user";

export default class PreferencesChatRoute extends RestrictedUserRoute {
  setupController(controller, user) {
    controller.set("model", user);
  }
}
