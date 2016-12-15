export class FormField {
  constructor(initialValue, validator = null) {
    this.value = initialValue;
    this.validator = validator;
  }
}

export const handleFieldChange = function (form, field) {
  return (event) => {
    let stateObject = {};

    stateObject[form] = { ...this.state[form] };
    stateObject[form][field].value = event.target.value;
    this.setState(stateObject);
  };
};

export const getFormValues = function(form) {
  return Object.keys(form).reduce((obj, key) => {
    obj[key] = form[key].value;

    return obj;
  }, {});
};

export const validateFormAndSetErrors = function(form) {
  let allValid = true;

  Object.keys(form).forEach((key) => {
    let errorMessage = form[key].validator(form[key].value);
    let formCopy = { ...form };

    formCopy[key].errorMessage = errorMessage;

    this.setState(
      formCopy
    );

    allValid = allValid && errorMessage === null;
  });

  return allValid;
};
