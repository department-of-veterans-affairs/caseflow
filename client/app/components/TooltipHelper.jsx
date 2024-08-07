import React from 'react';
import Tooltip from './Tooltip';

const MaybeAddTooltip = ({ option, children }) => {
  if (!option.tooltipText) {
    return children;
  }

  const keyId = `tooltip-${option.value}`;

  return (
    <Tooltip
      key={keyId}
      id={keyId}
      text={option.tooltipText}
      position="right"
      className="cf-radio-option-tooltip"
      offset={{ right: 15 }}
    >
      {children}
    </Tooltip>
  );
};

export default MaybeAddTooltip;
