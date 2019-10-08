import React from 'react';
import { css } from 'glamor';

import BENEFIT_TYPES from '../../constants/BENEFIT_TYPES.json';
import { COLORS } from '../constants/AppConstants';
import _ from 'lodash';

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

const issueClosedStatusStyling = css({
  color: COLORS.RED_DARK
});

export const AmaIssue = (props) => {
  return <li key={props.index} {...singleIssueStyling}>
    <div {...issueContentStyling}><strong>Benefit type</strong>: {BENEFIT_TYPES[props.issue.program]}</div>
    <div {...issueContentStyling}><strong>Issue</strong>: {props.issue.description}</div>
    { props.issue.diagnostic_code &&
      <div {...issueContentStyling}><strong>Diagnostic code</strong>: {props.issue.diagnostic_code}</div> }
    { props.issue.notes &&
      <div {...issueContentStyling} {...issueNoteStyling}>Note from NOD: {props.issue.notes}</div> }
    { props.issue.closed_status && props.issue.closed_status === 'withdrawn' &&
      <div {...issueContentStyling}>
        <strong>Disposition</strong>: <span {...issueClosedStatusStyling}>
          {_.capitalize(props.issue.closed_status)}</span>
      </div> }
    { props.children && React.cloneElement(props.children, { requestIssue: props.issue }) }
  </li>;
};

export default class AmaIssueList extends React.PureComponent {
  render = () => {
    const {
      requestIssues,
      children,
      errorMessages
    } = this.props;

    return <ol {...issueListStyling}>
      {requestIssues.map((issue, i) => {
        const error = errorMessages && errorMessages[issue.id];

        return <div key={i}>
          { error &&
            <span className="usa-input-error-message">
              {error}
            </span>
          }
          <div className={error ? 'usa-input-error' : ''}>
            <AmaIssue
              issue={issue}
              index={i} >
              {children}
            </AmaIssue>
          </div>
        </div>;
      })}
    </ol>;
  }
}
