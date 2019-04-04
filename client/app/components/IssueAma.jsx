import React from 'react';
import { css } from 'glamor';

import BENEFIT_TYPES from '../../constants/BENEFIT_TYPES.json';

const issueListStyling = css({
  paddingLeft: '1em'
});

const singleIssueStyling = css({
  width: '75%',
  marginBottom: '1.5em !important',
  paddingLeft: '0.75em',
  '@media(max-width: 1200px)': { width: '100%' }
});

const issueContentStyling = css({
  marginBottom: '0.3em'
});

const issueNoteStyling = css({
  fontStyle: 'italic'
});

export default class IssueAma extends React.PureComponent {
  render = () => {
    const {
      requestIssues,
      children,
      errorMessage
    } = this.props;

    return <ol {...issueListStyling}>
      {requestIssues.map((issue, i) => {
        return <div key={i}>
          { errorMessage &&
            <span className="usa-input-error-message">
              {errorMessage}
            </span>
          }
          <div className={errorMessage ? 'usa-input-error' : ''}>
            <li key={i} {...singleIssueStyling}>
              <div {...issueContentStyling}><strong>Benefit type</strong>: {BENEFIT_TYPES[issue.program]}</div>
              <div {...issueContentStyling}><strong>Issue</strong>: {issue.description}</div>
              { issue.diagnostic_code &&
                <div {...issueContentStyling}><strong>Diagnostic code</strong>: {issue.diagnostic_code}</div> }
              { issue.notes &&
                <div {...issueContentStyling} {...issueNoteStyling}>Note from NOD: {issue.notes}</div> }
            </li>
            { children && React.cloneElement(children, { requestIssue: issue }) }
          </div>
        </div>;
      })}
    </ol>;
  }
}
