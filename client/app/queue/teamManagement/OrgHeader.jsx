import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

const sectionHeadingStyling = css({
  fontSize: '3rem',
  fontWeight: 'bold'
});

export const OrgHeader = React.memo(({ children }) => {
  return <tr><td {...sectionHeadingStyling} colSpan="7">{children}</td></tr>;
});

OrgHeader.propTypes = {
  children: PropTypes.node
};
