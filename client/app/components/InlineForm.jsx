import React, { Children } from 'react';
import PropTypes from 'prop-types';

/**
 * Wrapper to display both labels and input fields inline
 */
export const InlineForm = ({ children }) => (
  <div className="usa-grid-half cf-inline-form">
    {Children.map(children, (child) => {
      return (<div className="cf-push-left">
        {child}
      </div>);
    })}
  </div>
);

InlineForm.propTypes = {

  /**
   * The form fields to display inline
   */
  children: PropTypes.node
};

export default InlineForm;
