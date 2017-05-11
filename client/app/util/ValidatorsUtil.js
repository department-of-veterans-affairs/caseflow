const ValidatorsUtil = {

  requiredValidator(value) {
    return !value || value.trim() === '';
  },

  dateValidator(value) {
    let dateRegex = /(0[1-9]|1[012])\/(0[1-9]|[12][0-9]|3[01])\/(19|20)\d\d/;

    return !dateRegex.test(value);
  }

};

export default ValidatorsUtil;
