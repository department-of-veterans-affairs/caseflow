export class FormField {
  constructor(initialValue, validator = null) {
    this.value = initialValue;
    this.validator = validator;
  }
}

export const handleFieldChange = (component) => (form, field) => (event) => {
  let stateObject = {};

  stateObject[form] = { ...component.state[form] };
  stateObject[form][field].value = event.target.value;
  component.setState(stateObject);
};
