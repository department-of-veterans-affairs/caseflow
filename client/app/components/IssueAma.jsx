import React from 'react';
import { css } from 'glamor';

import BENEFIT_TYPES from '../../constants/BENEFIT_TYPES.json';

const issueListStyling = css({
  paddingLeft: '1em'
});

const singleIssueStyling = css({
  width: '75%',
  marginBottom: '1.5em',
  paddingLeft: '0.75em',
  '@media(max-width: 1200px)': { width: '100%' }
});

const issueContentStyling = css({
  marginBottom: '0.3em'
});

const issueNoteStyling = css({
  fontStyle: 'italic'
});

export default function IssueAma(props) {
  return <ol {...issueListStyling}>
    {props.issues.map((issue, i) =>
      <li key={i} {...singleIssueStyling}>
        <div {...issueContentStyling}><strong>Benefit type</strong>: {BENEFIT_TYPES[issue.program]}</div>
        <div {...issueContentStyling}><strong>Issue</strong>: {issue.description}</div>
        { issue.diagnostic_code &&
          <div {...issueContentStyling}><strong>Diagnostic code</strong>: {issue.diagnostic_code}</div> }
        { issue.notes &&
          <div {...issueContentStyling} {...issueNoteStyling}>Note from NOD: {issue.notes}</div> }
      </li>
    )}
  </ol>;
}
