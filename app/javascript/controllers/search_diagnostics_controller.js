import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['journeyTab'];

  revealJourney() {
    // GOV.UK tabs do not reveal a panel when a link targets a row inside it.
    this.journeyTabTarget.click();
  }
}
