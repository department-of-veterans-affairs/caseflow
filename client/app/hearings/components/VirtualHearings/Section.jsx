import React from 'react';
import PropTypes from 'prop-types';

export const VirtualHearingSection = ({ label, children, hide }) =>
  !hide && (
    <React.Fragment>
      <div className="cf-help-divider" />
      <h2>{label}</h2>
      {children}
    </React.Fragment>
  );

VirtualHearingSection.defaultProps = {
  label: '',
  hide: false
};

VirtualHearingSection.propTypes = {
  children: PropTypes.node.isRequired,
  label: PropTypes.string,
  hide: PropTypes.bool,
};
