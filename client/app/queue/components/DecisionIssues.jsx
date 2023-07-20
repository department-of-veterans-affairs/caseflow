import * as React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';
import Button from '../../components/Button';
import ISSUE_DISPOSITIONS_BY_ID from '../../../constants/ISSUE_DISPOSITIONS_BY_ID';
import { LinkIcon } from '../../components/icons/LinkIcon';
import HearingWorksheetAmaIssues from '../../hearings/components/hearingWorksheet/HearingWorksheetAmaIssues';

const TEXT_INDENTATION = '10px';

export const contestedIssueStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  padding: `5px ${TEXT_INDENTATION}`,
  margin: '10px 0'
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

export default class DecisionIssues extends React.PureComponent {
  static generateDecisionIssues = (requestIssue, props) => {
    const { decisionIssues, openDecisionHandler, openDeleteAddedDecisionIssueHandler, hideDelete, hideEdit } = props;

    return decisionIssues.
      filter((decisionIssue) => {
        return decisionIssue.request_issue_ids.includes(requestIssue.id);
      }).
      map((decisionIssue) => {
        const linkedDecisionIssue = decisionIssue.request_issue_ids.length > 1;

        return (
          <div {...outerDiv} key={decisionIssue.id} className="decision-issue">
            <div {...grayLine} />
            <div {...decisionIssueDiv}>
              <div {...flexContainer}>
                Decision
                <div>
                  {openDeleteAddedDecisionIssueHandler && !hideDelete({ decisionIssue }) && (
                    <span>
                      <Button
                        name="Delete"
                        id={`delete-issue-${requestIssue.id}-${decisionIssue.id}`}
                        onClick={() => {
                          openDeleteAddedDecisionIssueHandler(requestIssue.id, decisionIssue);
                        }}
                        classNames={['cf-btn-link']}
                      />
                    </span>
                  )}
                  {openDecisionHandler && !hideEdit({ decisionIssue }) && (
                    <span>
                      <Button
                        name="Edit"
                        id={`edit-issue-${requestIssue.id}-${decisionIssue.id}`}
                        onClick={openDecisionHandler(requestIssue.id, decisionIssue)}
                        classNames={['cf-btn-link']}
                      />
                    </span>
                  )}
                </div>
              </div>
              <div {...flexContainer}>
                <span {...descriptionSpan}>
                  {decisionIssue.description}
                  {decisionIssue.diagnostic_code && <div>Diagnostic code: {decisionIssue.diagnostic_code}</div>}
                </span>
                <span>{ISSUE_DISPOSITIONS_BY_ID[decisionIssue.disposition]}</span>
              </div>
              {linkedDecisionIssue && (
                <div {...noteDiv} {...verticalSpaceDiv}>
                  <LinkIcon /> Added to {decisionIssue.request_issue_ids.length} issues
                </div>
              )}
            </div>
          </div>
        );
      });
  };

  render = () => {
    const { requestIssue, openDecisionHandler, hearingWorksheet } = this.props;

    return (
      <div>
        {DecisionIssues.generateDecisionIssues(requestIssue, this.props)}
        {openDecisionHandler && (
          <React.Fragment>
            <div {...buttonDiv}>
              <Button
                name="+ Add decision"
                id={`add-decision-${requestIssue.id}`}
                onClick={openDecisionHandler(requestIssue.id)}
                classNames={['usa-button-secondary']}
              />
            </div>
          </React.Fragment>
        )}
        {hearingWorksheet && <HearingWorksheetAmaIssues issue={requestIssue} />}
      </div>
    );
  };
}

DecisionIssues.propTypes = {
  requestIssue: PropTypes.shape({
    id: PropTypes.number,
    program: PropTypes.string,
    description: PropTypes.string,
    notes: PropTypes.string,
    diagnostic_code: PropTypes.string,
    closed_status: PropTypes.string,
    remand_reasons: PropTypes.array
  }),
  openDecisionHandler: PropTypes.func,
  hearingWorksheet: PropTypes.object,
  hideDelete: PropTypes.func,
  hideEdit: PropTypes.func
};

DecisionIssues.defaultProps = {
  hideDelete: () => false,
  hideEdit: () => false
};
