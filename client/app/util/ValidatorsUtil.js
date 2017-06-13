/*
This is a duplicate of logic found in the validators folder and in
BaseForm.jsx. As we move more towards using Redux, these validators
better fit our expected patterns.
 */

const MAX_LENGTH = 40;

const ValidatorsUtil = {

  requiredValidator(value) {
    return !value || value.trim() === '';
  },

  lengthValidator(value) {
    return value.trim().length > MAX_LENGTH;
  },

  dateValidator(value) {
    let dateRegex = /(0[1-9]|1[012])\/(0[1-9]|[12][0-9]|3[01])\/(19|20)\d\d/;

    return !dateRegex.test(value);
  },

  scrollToAndFocusFirstError() {
    let errors = document.getElementsByClassName('usa-input-error-message');

    if (errors.length > 0) {
      window.scrollBy(0, errors[0].parentElement.getBoundingClientRect().top);
      Array.from(errors[0].parentElement.childNodes).forEach((node) => {
        if (node.nodeName === 'INPUT' ||
            node.nodeName === 'SELECT') {
          node.focus();
        }
      });
    }
  }
};

export default ValidatorsUtil;
