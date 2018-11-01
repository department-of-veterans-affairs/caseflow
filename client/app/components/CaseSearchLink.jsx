import React from 'react';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { MagnifyingGlass } from './RenderFunctions';
import { COLORS } from '../constants/AppConstants';

const containerStyling = css({
  display: 'inline table',
  float: 'left',
  marginRight: '3rem'
});
const iconStyling = css({
  display: 'table-cell',
  padding: '0.75rem 0.25rem 0 0',
  verticalAlign: 'middle'
});
const textStyling = css({
  color: COLORS.PRIMARY,
  display: 'table-cell',
  fontSize: '1.7rem',
  lineHeight: '4em',
  marginBottom: 0
});

const CaseSearchLink = (props) => <div {...containerStyling}>
  <Link href="/search" target={props.newWindow ? '_blank' : '_self'}>
    <span {...iconStyling}><MagnifyingGlass color={COLORS.PRIMARY} /></span>
    <h3 {...textStyling}>Search cases</h3>
  </Link>
</div>;

export default CaseSearchLink;
