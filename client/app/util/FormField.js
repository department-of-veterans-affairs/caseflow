export class FormField {
  constructor(initialValue, validator = null) {
    this.value = initialValue;
    // Always make validator an array of all the validators.
    this.validator = [].concat(validator);
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
  // This variable stays true until a validator fails
  // in which case we return false. Otherwise all fields
  // are vavlid, and we retrun true.
  let allValid = true;

  Object.keys(form).
    filter((key) => form[key].validator !== null).
    forEach((key) => {
      form[key].validator.reduce((errorMessage, validator) => {
        if (errorMessage) {
          return errorMessage;
        }

        let message = validator(form[key].value);
        let formCopy = { ...form };

        formCopy[key].message = message;

        this.setState(
          formCopy
        );

        allValid = allValid && message === null;

        return message;
      }, null);
    });

  return allValid;
};

export const scrollToAndFocusFirstError = function() {
  let errors = document.getElementsByClassName("usa-input-error-message");

  if (errors.length > 0) {
    window.scrollBy(0, errors[0].parentElement.getBoundingClientRect().top);
    Array.from(errors[0].parentElement.childNodes).forEach((node) => {
      if (node.nodeName === 'INPUT' ||
          node.nodeName === 'SELECT') {
        node.focus();
      }
    });
  }
};
