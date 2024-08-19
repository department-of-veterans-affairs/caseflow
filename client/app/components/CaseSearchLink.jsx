import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { MagnifyingGlassIcon } from './icons/MagnifyingGlassIcon';
import { COLORS } from '../constants/AppConstants';

const containerStyling = {
  display: 'inline table',
  float: 'left',
  marginRight: '3rem'
};
const iconStyling = {
  display: 'table-cell',
  padding: '0.75rem 0.25rem 0 0',
  verticalAlign: 'middle'
};
const textStyling = {
  color: COLORS.PRIMARY,
  display: 'table-cell',
  fontSize: '1.7rem',
  fontWeight: 900,
  lineHeight: '4em',
  marginBottom: 0
};

const CaseSearchLink = (props) => <div style={containerStyling}>
  <Link href="/search" target={props.newWindow ? '_blank' : '_self'}>
    <span style={iconStyling}><MagnifyingGlassIcon color={COLORS.PRIMARY} size={24} /></span>
    <p style={textStyling}>Search cases</p>
  </Link>
</div>;

CaseSearchLink.propTypes = {
  newWindow: PropTypes.bool
};

export default CaseSearchLink;
