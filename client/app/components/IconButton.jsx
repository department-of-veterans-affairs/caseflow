import React, { PropTypes } from 'react';

const IconButton = ({ handleActivate, label, getRef, iconName, className = '' }) => {
  const handleKeyDown = (event) => {
    if (event.key === ' ' || event.key === 'Enter') {
      handleActivate(event);
      event.preventDefault();
    }
  };

  return <i className={`${className} fa fa-1 ${iconName} cf-icon-button`}
      role="button" aria-label={label} tabIndex="0"
      ref={getRef}
      onClick={handleActivate} onKeyDown={handleKeyDown}></i>;
};

IconButton.displayName = 'IconButton';

IconButton.propTypes = {
  label: PropTypes.string.isRequired,
  iconName: PropTypes.string.isRequired,
  handleActivate: PropTypes.func
};

export default IconButton;
