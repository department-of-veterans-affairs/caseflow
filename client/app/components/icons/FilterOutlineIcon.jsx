import React from 'react';
import PropTypes from 'prop-types';
import { SelectedFilterIcon } from './SelectedFilterIcon';
import { UnselectedFilterIcon } from './UnselectedFilterIcon';

export const FilterOutlineIcon = (props) => {
  const { handleActivate, label, getRef, selected } = props;

  const handleKeyDown = (event) => {
    if (event.key === ' ' || event.key === 'Enter') {
      handleActivate(event);
      event.preventDefault();
    }
  };

  const defaults = {
    role: 'button',
    getRef,
    label,
    className: 'table-icon',
    tabIndex: '0',
    onKeyDown: handleKeyDown,
    onClick: handleActivate
  };

  return (selected ? <SelectedFilterIcon {...defaults} /> : <UnselectedFilterIcon {...defaults} />);
};

FilterOutlineIcon.propTypes = {
  label: PropTypes.string.isRequired,
  iconName: PropTypes.string,
  handleActivate: PropTypes.func,
  getRef: PropTypes.func,
  className: PropTypes.string,
  selected: PropTypes.bool
};
