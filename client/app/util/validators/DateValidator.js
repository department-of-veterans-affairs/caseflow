const DATE_REGEX = /(0[1-9]|1[012])\/(0[1-9]|[12][0-9]|3[01])\/(19|20)\d\d/;


const dateValidator =
  (message = 'The date must be in mm/dd/yyyy format.') => function(value) {

    if (!DATE_REGEX.test(value)) {
      return message;
    }

    return null;
  };

export default dateValidator;
