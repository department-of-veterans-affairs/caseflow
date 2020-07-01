import React from 'react';

export const VirtualHearingSection = ({ label, children, hide }) =>
  !hide && (
    <React.Fragment>
      <div className="cf-help-divider" />
      <h3>{label}</h3>
      {children}
    </React.Fragment>
  );
