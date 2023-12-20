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
const youveGotMailStyle = css({
  position: 'absolute',
  background: COLORS.RED_DARK,
  left: '10px',
  height: 'auto',
  width: 'auto',
  margin: '0',
  padding: '6px',
  borderRadius: '50%'
});

const InboxLink = (props) => <div {...containerStyling}>
  <Link href="/inbox" target={props.newWindow ? '_blank' : '_self'}>
    <i className="fa fa-envelope-o" aria-hidden="true">
      { props.youveGotMail && <span {...youveGotMailStyle}></span> }
    </i>
    <h3 {...textStyling}>Inbox</h3>
  </Link>
</div>;

InboxLink.propTypes = {
  newWindow: PropTypes.bool,
  youveGotMail: PropTypes.bool
};

export default InboxLink;
