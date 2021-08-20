import React from 'react';
import PropTypes from 'prop-types';

import { marginTop } from '../details/style';

export const VirtualHearingSection = ({ label, children, hide, showDivider, formFieldsOnly }) =>
  !hide && (
    <React.Fragment>
      {showDivider ? <div className="cf-help-divider" /> : <div {...marginTop(30)} />}
      {formFieldsOnly ? <strong> {label}</strong> : <h2>{label}</h2>}
      {children}
    </React.Fragment>
  );

VirtualHearingSection.defaultProps = {
  label: '',
  hide: false,
  showDivider: true,
  formFieldsOnly: false
};

VirtualHearingSection.propTypes = {
  children: PropTypes.node.isRequired,
  label: PropTypes.string,
  showDivider: PropTypes.bool,
  formFieldsOnly: PropTypes.bool,
  hide: PropTypes.bool,
};
