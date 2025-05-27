import Component from "@ember/component";
import icon from "discourse/helpers/d-icon";

export default class extends Component {
  <template>
    <div class="github-verified-username">
      <a
        target="_blank"
        rel="noopener noreferrer"
        href="https://github.com/{{this.username}}"
      >
        {{icon "fab-github"}}
        {{this.username}}
      </a>
    </div>
  </template>
}
