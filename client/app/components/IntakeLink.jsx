import React from 'react';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { COLORS } from '../constants/AppConstants';
import PropTypes from 'prop-types';

const containerStyling = css({
  display: 'inline table',
  position: 'relative',
  float: 'left',
  marginRight: '3rem'
});
const textStyling = css({
  color: COLORS.PRIMARY,
  display: 'table-cell',
  fontSize: '1.7rem',
  lineHeight: '4em',
  paddingLeft: '0.5rem',
  marginBottom: 0
});

const IntakeLink = (props) => <div {...containerStyling}>
  <Link href="/intake" target={props.newWindow ? '_blank' : '_self'}>
    <i className="fa fa-inbox" aria-hidden="true"></i>
    <h3 {...textStyling}>Intake</h3>
  </Link>
</div>;

IntakeLink.propTypes = {
  newWindow: PropTypes.bool
};

export default IntakeLink;
