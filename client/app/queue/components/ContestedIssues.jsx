import * as React from 'react';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';
import Button from '../../components/Button';
import ISSUE_DISPOSITIONS_BY_ID from '../../../constants/ISSUE_DISPOSITIONS_BY_ID.json';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES.json';
import { LinkSymbol } from '../../components/RenderFunctions';
import HearingWorksheetAmaIssues from '../../hearings/components/HearingWorksheetAmaIssues';

const TEXT_INDENTATION = '10px';

export const contestedIssueStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  padding: `5px ${TEXT_INDENTATION}`,
  margin: '10px 0'
});

const indentedIssueStyling = css({
  margin: `0 ${TEXT_INDENTATION}`
});

const buttonDiv = css({
  textAlign: 'right',
  margin: '20px 0'
});

const outerDiv = css({
  marginLeft: '50px',
  marginTop: '5px'
});

const decisionIssueDiv = css({
  border: `2px solid ${COLORS.GREY_LIGHT}`,
  borderRadius: '5px',
  padding: '10px'
});

const verticalSpaceDiv = css({
  marginTop: '10px'
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

const noteDiv = css({
  fontSize: '1.5rem',
  color: COLORS.GREY
});

const errorTextSpacing = css({
  margin: TEXT_INDENTATION
});

export default class ContestedIssues extends React.PureComponent {
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
    const {
      requestIssues,
      decisionIssues,
      highlight,
      openDecisionHandler,
      numbered,
      hearingWorksheet
    } = this.props;

    const listStyle = css({
      listStyleType: numbered ? 'decimal' : 'none',
      paddingLeft: numbered ? 'inherit' : '0'
    });

    const listPadding = css({
      paddingLeft: numbered ? '5px' : '0'
    });

    return <ol {...listStyle}>{requestIssues.map((issue) => {
      const hasDecisionIssue = decisionIssues.some(
        (decisionIssue) => decisionIssue.request_issue_ids.includes(issue.id)
      );
      const shouldShowError = highlight && !hasDecisionIssue;

      return <li {...listPadding} key={issue.id}>
        <div {...contestedIssueStyling}>
          Issue
        </div>
        { shouldShowError &&
          <span {...errorTextSpacing} className="usa-input-error-message">
            You must add a decision before you continue.
          </span>
        }
        <div {...indentedIssueStyling} className={shouldShowError ? 'usa-input-error' : ''}>
          <div {...verticalSpaceDiv}>Benefit type: {BENEFIT_TYPES[issue.program]}</div>
          {issue.description}
          { issue.diagnostic_code &&
            <div>Diagnostic code: {issue.diagnostic_code}</div>
          }
          { issue.notes &&
            <div {...noteDiv} {...verticalSpaceDiv}>Note: "{issue.notes}"</div>
          }

          {this.decisionIssues(issue)}
          { openDecisionHandler &&
            <React.Fragment>
              <div {...buttonDiv}>
                <Button
                  name="+ Add decision"
                  id={`add-decision-${issue.id}`}
                  onClick={openDecisionHandler(issue.id)}
                  classNames={['usa-button-secondary']}
                />
              </div>
            </React.Fragment>
          }
          { hearingWorksheet && <HearingWorksheetAmaIssues issue={issue} /> }
        </div>
      </li>;
    })}
    </ol>;
  }
}
