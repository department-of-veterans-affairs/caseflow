import React from 'react';
import PropTypes from 'prop-types';

import { css } from 'glamor';

const cardStyles = css({
  boxShadow: '0px 4px 4px rgba(0, 0, 0, 0.25)',
  padding: '2rem'
});

export const Card = ({ children, ...rest }) => <div {...cardStyles} {...rest}>{children}</div>;

Card.propTypes = {
  children: PropTypes.element.isRequired
};
