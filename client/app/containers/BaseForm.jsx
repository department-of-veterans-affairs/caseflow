import React from 'react';
import ReactDOM from 'react-dom';

export default class BaseForm extends React.Component {

  handleFieldChange = function (form, field) {
    return (value) => {
      let stateObject = {};

      stateObject[form] = { ...this.state[form] };
      stateObject[form][field].value = value;
      this.setState(stateObject);
    };
  };

  validateFormAndSetErrors = function(form) {
        // This variable stays true until a validator fails
        // in which case we return false. Otherwise all fields
        // are valid, and we return true.
    let allValid = true;
    let formCopy = { ...form };

    Object.keys(form).forEach((key) => {
      let errorMessage = form[key].validator.reduce(
                (message, validator) => message || validator(form[key].value), null);

      allValid = allValid && !errorMessage;

      formCopy[key].errorMessage = errorMessage;
    });

    if (allValid) {
      this.setState({
        validating: null
      });
    }

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

  formValidating = function() {
    this.setState({
      validating: this
    });
  }

  scrollToAndFocusFirstError = function() {
    let erroredForm = ReactDOM.findDOMNode(this.state.validating);
    let errors = erroredForm.getElementsByClassName("usa-input-error-message");

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
    if (this.state.validating) {
      this.scrollToAndFocusFirstError();
    }
  }
}
