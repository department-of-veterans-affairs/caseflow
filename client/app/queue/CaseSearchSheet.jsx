import { css } from 'glamor';
import React from 'react';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

import CaseListSearch from './CaseListSearch';
import { fullWidth } from './constants';

import COPY from '../../COPY.json';

const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '5rem',
  marginBottom: '5rem'
});

export default class CaseSearchSheet extends React.PureComponent {
  render = () => <AppSegment filledBackground>
    <div>
      <h1 className="cf-push-left" {...fullWidth}>{COPY.CASE_SEARCH_HOME_PAGE_HEADING}</h1>
      <p>{COPY.CASE_SEARCH_INPUT_INSTRUCTION}</p>
      <CaseListSearch elementId="searchBarEmptyList" />
      <hr {...horizontalRuleStyling} />
      <p><Link href="/help">Caseflow Help</Link></p>
    </div>
  </AppSegment>;
}
