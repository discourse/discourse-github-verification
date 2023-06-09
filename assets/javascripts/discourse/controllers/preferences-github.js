import Controller from "@ember/controller";
import I18n from "I18n";
import { ajax } from "discourse/lib/ajax";
import { action } from "@ember/object";
import { getAbsoluteURL } from "discourse-common/lib/get-url";
import { inject as service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";

export default class PreferencesGithubController extends Controller {
  @service siteSettings;
  @service dialog;
  @tracked githubUsername = this.model.custom_fields.github_verified_username;

  @action
  login() {
    window.location = getAbsoluteURL("/github-verification/auth-url");
  }

  @action
  clear() {
    this.dialog.confirm({
      message: I18n.t("discourse_github_verification.clear_confirmation"),
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
