import React from 'react';

export default class BaseForm extends React.Component {

  handleFieldChange = function (form, field) {
    return (event) => {
      let stateObject = {};

      stateObject[form] = { ...this.state[form] };
      stateObject[form][field].value = event.target.value;
      this.setState(stateObject);
    };
  };

  validateFormAndSetErrors = function(form) {
        // This variable stays true until a validator fails
        // in which case we return false. Otherwise all fields
        // are vavlid, and we retrun true.
    let allValid = true;
    let formCopy = { ...form };

    Object.keys(form).forEach((key) => {
      let errorMessage = form[key].validator.reduce(
                (message, validator) => message || validator(form[key].value), null);

      allValid = allValid && !errorMessage;

      formCopy[key].errorMessage = errorMessage;
    });

    this.setState(
            formCopy
        );

    return allValid;
  };

  getFormValues = function(form) {
    return Object.keys(form).reduce((obj, key) => {
      obj[key] = form[key].value;

      return obj;
    }, {});
  };

  scrollToAndFocusFirstError = function() {
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

  componentDidUpdate() {
    if (this.setErrors) {
      this.scrollToAndFocusFirstError();
    }
    this.setErrors = false;
  }
}
