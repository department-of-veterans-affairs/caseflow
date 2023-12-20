export default class FormField {
  constructor(initialValue, validator = []) {
    this.value = initialValue;
    // Always make validator an array of all the validators.
    this.validator = [].concat(validator);
  }
}
