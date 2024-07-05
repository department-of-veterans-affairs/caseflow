import React from 'react';
import PropTypes from 'prop-types';
import cx from 'classnames';

const ToggleSwitch = ({
  id,
  name,
  selected,
  toggleSelected,
  optionLabels,
  disabled,
  isIdle
}) => {

  const buttonStyles = cx('toggleButton', {
    toggleSwitchDisabled: disabled
  });

  const h5Style = cx('toggleButtonText', {
    switchDisabled: disabled,
    switchIdle: isIdle,
    switchOn: selected,
    switchOff: !selected
  });

  return (
    <button
      className={buttonStyles}
      disabled={disabled}
      id={id}
      name={name}
      onClick={toggleSelected}>
      <span className="toggleButtonSpace"></span>
      <h5
        className={h5Style}
      >
        {selected ? optionLabels[0] : optionLabels[1]}
      </h5>
    </button>
  );
};

// Set optionLabels for rendering.
ToggleSwitch.defaultProps = {
  optionLabels: ['On', 'Off']
};

ToggleSwitch.propTypes = {
  selected: PropTypes.bool.isRequired,
  toggleSelected: PropTypes.func,
  id: PropTypes.string,
  name: PropTypes.string,
  optionLabels: PropTypes.array,
  disabled: PropTypes.bool,
  isIdle: PropTypes.bool
};

export default ToggleSwitch;
