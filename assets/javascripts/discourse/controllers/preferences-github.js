import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { getAbsoluteURL } from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";

export default class PreferencesGithubController extends Controller {
  @service dialog;

  @tracked githubUsername = this.model.custom_fields.github_verified_username;

  @action
  login() {
    window.location = getAbsoluteURL("/github-verification/auth-url");
  }

  @action
  clear() {
    this.dialog.confirm({
      message: i18n("discourse_github_verification.clear_confirmation"),
      didConfirm: () => {
        ajax(`/github-verification/clear/${this.model.id}`, {
          method: "DELETE",
        })
          .then(() => {
            this.githubUsername = null;
          })
          .catch(popupAjaxError);
      },
    });
  }
}
