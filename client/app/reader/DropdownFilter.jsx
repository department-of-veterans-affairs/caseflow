import React, { PropTypes } from 'react';
import { closeSymbolHtml } from '../components/RenderFunctions';

const DropdownFilter = ({ children, baseCoordinates }) => {
  if (!baseCoordinates) {
    return null;
  }
  const positioning = {
    top: baseCoordinates.top,
    left: baseCoordinates.left
  };

  return <div className="cf-dropdown-filter" style={positioning}>
    <div>
      Clear category filter {closeSymbolHtml()}
    </div>
    {children}
  </div>;
};

export default DropdownFilter;
