import React from 'react';
import PropTypes from 'prop-types';
import cx from 'classnames';
import styles from './ToggleSwitch.module.scss';

const ToggleSwitch = ({
  id,
  name,
  selected,
  toggleSelected,
  optionLabels,
  disabled
}) => {
  return (
    <button
      className={
        disabled ?
          cx(styles.toggleButton, styles.toggleSwitchDisabled) :
          styles.toggleButton
      }
      disabled={disabled}
      id={id}
      name={name}
      onClick={toggleSelected}>
      <span className={styles.toggleButtonSpace}></span>
      <h5
        className={
          `${styles.toggleButtonText} ${selected ?
            styles.switchOn :
            styles.switchOff} ${disabled ?
              styles.switchDisabled :
              ''}`}
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
  disabled: PropTypes.bool
};

export default ToggleSwitch;
