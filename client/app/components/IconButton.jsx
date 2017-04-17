import React, { PropTypes } from 'react';

export default ({ handleActivate, label, getRef, iconName, className = '' }) => {
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
