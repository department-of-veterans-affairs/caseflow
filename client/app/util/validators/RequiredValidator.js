const requiredValidator = (message) => function(value) {
  if (value === '') {
    return message;
  }

  return null;
};

export default requiredValidator;
