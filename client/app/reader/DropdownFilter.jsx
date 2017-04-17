import React, { PropTypes } from 'react';
import { closeSymbolHtml } from '../components/RenderFunctions';

const DropdownFilter = ({ children }) => {
  return <div className="cf-form-dropdown">
    <div>
      Clear category filter {closeSymbolHtml()}
    </div>
    {children}
  </div>;
};

export default DropdownFilter;
