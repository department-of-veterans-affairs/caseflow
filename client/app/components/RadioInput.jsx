import React from 'react';
import PropTypes from 'prop-types';
import ACD_LEVERS from '../../constants/ACD_LEVERS';

const RadioInput = ({ handleChange, name, idPart, option, controlled, value, inputRef, inputProps }) => {
  const isChecked = controlled ? value === option.value : option.checked;

  return (
    <input
      onChange={handleChange}
      name={name}
      type={ACD_LEVERS.data_types.radio}
      id={`${idPart}_${option.value}`}
      value={option.value}
      checked={isChecked}
      disabled={Boolean(option.disabled)}
      ref={inputRef}
      {...inputProps}
    />
  );
};

RadioInput.propTypes = {
  handleChange: PropTypes.func.isRequired,
  name: PropTypes.string.isRequired,
  idPart: PropTypes.string.isRequired,
  option: PropTypes.object.isRequired,
  controlled: PropTypes.bool.isRequired,
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.bool]).isRequired,
  inputRef: PropTypes.oneOfType([
    PropTypes.func,
    PropTypes.shape({ current: PropTypes.instanceOf(Element) }),
  ]),
  inputProps: PropTypes.object,
};

export default RadioInput;
