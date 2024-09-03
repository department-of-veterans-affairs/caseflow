// whitelist alphanumberic, and specified special characters to match VBMS
const DESCRIPTION_REGEX = /^[a-zA-Z0-9\s.\-_|/\\@#~=%,;?!'"`():$+*^[\]&><{}]*$/;

const descriptionValidator = (message = 'Invalid character') => function(value) {

  if (!DESCRIPTION_REGEX.test(value)) {
    return message;
  }

  return null;
};

export default descriptionValidator;
