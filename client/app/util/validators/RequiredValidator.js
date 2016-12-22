const requiredValidator = (message) => function(value) {
  if (value.trim() === '') {
    return message;
  }

  return null;
};

export default requiredValidator;
