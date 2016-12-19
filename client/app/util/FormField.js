export class FormField {
  constructor(initialValue, validator = null) {
    this.value = initialValue;
    // Always make validator an array of all the validators.
    if (validator !== null) {
      if (Array.isArray(validator)) {
        this.validator = validator;  
      } else {
        this.validator = [validator];
      }
    } else {
      this.validator = null;
    }
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

  Object.keys(form)
    .filter((key) => form[key].validator !== null)
    .forEach((key) => {
      form[key].validator.reduce((errorMessage, validator) => {
        if (errorMessage) {
          return errorMessage;
        }

        errorMessage = validator(form[key].value);
        let formCopy = { ...form };

        formCopy[key].errorMessage = errorMessage;

        this.setState(
          formCopy
        );

        allValid = allValid && errorMessage === null;
        return errorMessage;
      }, null);
    });

  return allValid;
};

export const scrollToAndFocusFirstError = function() {
  let errors = document.getElementsByClassName("usa-input-error-message");
  if (errors.length > 0)
  {
    window.scrollBy(0, errors[0].parentElement.getBoundingClientRect().top);
    errors[0].parentElement.childNodes.forEach((node) => {
      if (node.nodeName === 'INPUT' ||
          node.nodeName === 'SELECT') {
        node.focus();
      }
    });
  }
};
