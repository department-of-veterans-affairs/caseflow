import React from 'react';
import { css } from 'glamor';

import { COLORS } from '../constants/AppConstants';
import BENEFIT_TYPES from '../../constants/BENEFIT_TYPES.json';
import ISSUE_DISPOSITIONS_BY_ID from '../../constants/ISSUE_DISPOSITIONS_BY_ID.json';
import Button from './Button';
import { LinkSymbol } from './RenderFunctions';

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

const buttonDiv = css({
  textAlign: 'right',
  margin: '20px 0'
});

const outerDiv = css({
  marginLeft: '50px',
  marginTop: '5px'
});

const noteDiv = css({
  fontSize: '1.5rem',
  color: COLORS.GREY
});

const verticalSpaceDiv = css({
  marginTop: '10px'
});

const decisionIssueDiv = css({
  border: `2px solid ${COLORS.GREY_LIGHT}`,
  borderRadius: '5px',
  padding: '10px'
});

const descriptionSpan = css({
  marginRight: '10px'
});

const grayLine = css({
  width: '4px',
  minHeight: '20px',
  background: COLORS.GREY_LIGHT,
  marginLeft: '20px',
  marginBottom: '5px'
});

const flexContainer = css({
  display: 'flex',
  justifyContent: 'space-between'
});

export default class IssueAma extends React.PureComponent {
  decisionIssues = (requestIssue) => {
    const {
      decisionIssues,
      openDecisionHandler,
      openDeleteAddedDecisionIssueHandler
    } = this.props;

    return decisionIssues.filter((decisionIssue) => {
      return decisionIssue.request_issue_ids.includes(requestIssue.id);
    }).map((decisionIssue) => {
      const linkedDecisionIssue = decisionIssue.request_issue_ids.length > 1;

      return <div {...outerDiv} key={decisionIssue.id} className="decision-issue">
        <div {...grayLine} />
        <div {...decisionIssueDiv}>
          <div {...flexContainer}>
            Decision
            <div>
              {openDeleteAddedDecisionIssueHandler && <span>
                <Button
                  name="Delete"
                  id={`delete-issue-${requestIssue.id}-${decisionIssue.id}`}
                  onClick={() => {
                    openDeleteAddedDecisionIssueHandler(requestIssue.id, decisionIssue);
                  }}
                  classNames={['cf-btn-link']}
                />
              </span>}
              {openDecisionHandler && <span>
                <Button
                  name="Edit"
                  id={`edit-issue-${requestIssue.id}-${decisionIssue.id}`}
                  onClick={openDecisionHandler(requestIssue.id, decisionIssue)}
                  classNames={['cf-btn-link']}
                />
              </span>}
            </div>
          </div>
          <div {...flexContainer}>
            <span {...descriptionSpan}>
              {decisionIssue.description}
              { decisionIssue.diagnostic_code &&
              <div>Diagnostic code: {decisionIssue.diagnostic_code}</div>
              }
            </span>
            <span>
              {ISSUE_DISPOSITIONS_BY_ID[decisionIssue.disposition]}
            </span>
          </div>
          {linkedDecisionIssue && <div {...noteDiv} {...verticalSpaceDiv}>
            <LinkSymbol /> Added to {decisionIssue.request_issue_ids.length} issues
          </div>}
        </div>
      </div>;
    });
  }

  render = () => {
    return <ol {...issueListStyling}>
      {this.props.requestIssues.map((issue, i) => {
        const hasDecisionIssue = this.props.decisionIssues.some(
          (decisionIssue) => decisionIssue.request_issue_ids.includes(issue.id)
        );
        const shouldShowError = this.props.highlight && !hasDecisionIssue;

        return <div key={i}>
          { shouldShowError &&
            <span className="usa-input-error-message">
              You must add a decision before you continue.
            </span>
          }
          <div className={shouldShowError ? 'usa-input-error' : ''}>
            <li key={i} {...singleIssueStyling}>
              <div {...issueContentStyling}><strong>Benefit type</strong>: {BENEFIT_TYPES[issue.program]}</div>
              <div {...issueContentStyling}><strong>Issue</strong>: {issue.description}</div>
              { issue.diagnostic_code &&
                <div {...issueContentStyling}><strong>Diagnostic code</strong>: {issue.diagnostic_code}</div> }
              { issue.notes &&
                <div {...issueContentStyling} {...issueNoteStyling}>Note from NOD: {issue.notes}</div> }
            </li>
            { this.decisionIssues(issue) }
            { this.props.openDecisionHandler &&
              <React.Fragment>
                <div {...buttonDiv}>
                  <Button
                    name="+ Add decision"
                    id={`add-decision-${issue.id}`}
                    onClick={this.props.openDecisionHandler(issue.id)}
                    classNames={['usa-button-secondary']}
                  />
                </div>
              </React.Fragment>
            }
          </div>
        </div>
      })}
    </ol>;
  } 
}
