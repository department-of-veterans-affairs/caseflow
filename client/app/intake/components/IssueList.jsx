import _ from 'lodash';
import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY.json';
import { FORM_TYPES } from '../constants';
import AddedIssue from './AddedIssue';
import Button from '../../components/Button';
import Dropdown from '../../components/Dropdown';
import EditContentionTitle from '../components/EditContentionTitle';

import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';

const nonEditableIssueStyling = css({
  color: COLORS.GREY,
  fontStyle: 'Italic'
});

export default class IssuesList extends React.Component {

  generateIssueActionOptions = (issue) => {
    let options = [];

    if (!issue.editable) {
      return options;
    } else if (issue.correctionType && issue.endProductCleared) {
      options.push({ displayText: 'Undo correction',
        value: 'undo_correction' });
    } else if (issue.correctionType) {
      options.push(
        { displayText: 'Remove issue',
          value: 'remove' }
      );
    } else if (issue.endProductCleared) {
      options.push({ displayText: 'Correct issue',
        value: 'correct' });
    } else if (!issue.withdrawalDate && !issue.withdrawalPending) {
      options.push(
        { displayText: 'Withdraw issue',
          value: 'withdraw' },
        { displayText: 'Remove issue',
          value: 'remove' }
      );
    }

    return options;
  }

  render = () => {
    const {
      issues,
      intakeData,
      formType,
      onClickIssueAction,
      withdrawReview,
      featureToggles
    } = this.props;

    const {
      withdrawDecisionReviews,
      editContentionText
    } = featureToggles;

    return <div className="issues">
      <div>
        { withdrawReview && <p className="cf-red-text">{COPY.INTAKE_WITHDRAWN_BANNER}</p> }
        { issues.map((issue) => {
          const editableContentionText = Boolean(formType !== FORM_TYPES.APPEAL.key &&
            !issue.category && !issue.ineligibleReason && !issue.endProductCleared && !issue.isUnidentified
          );
          let issueActionOptions = this.generateIssueActionOptions(issue);

          return <div className="issue-container" key={`issue-container-${issue.index}`}>
            <div
              className="issue"
              data-key={`issue-${issue.index}`}
              key={`issue-${issue.index}`}
              id={`issue-${issue.referenceId}`}>

              <AddedIssue
                issue={issue}
                issueIdx={issue.index}
                requestIssues={intakeData.requestIssues}
                legacyOptInApproved={intakeData.legacyOptInApproved}
                legacyAppeals={intakeData.legacyAppeals}
                formType={formType} />

              { _.isEmpty(issueActionOptions) && <div className="issue-action">
                <span {...nonEditableIssueStyling}>{COPY.INTAKE_RATING_MAY_BE_PROCESS}</span>
              </div> }

              { !_.isEmpty(issueActionOptions) && <div className="issue-action">
                { withdrawDecisionReviews && <Dropdown
                  name={`issue-action-${issue.index}`}
                  label="Actions"
                  hideLabel
                  options={issueActionOptions}
                  defaultText="Select action"
                  onChange={(option) => onClickIssueAction(issue.index, option)}
                />
                }
                { !withdrawDecisionReviews && <Button
                  onClick={() => onClickIssueAction(issue.index)}
                  classNames={['cf-btn-link', 'remove-issue']}
                >
                  <i className="fa fa-trash-o" aria-hidden="true"></i><br />Remove
                </Button>
                }
              </div> }
            </div>
            {editContentionText && editableContentionText && <EditContentionTitle
              issue= {issue}
              issueIdx={issue.index} />}
          </div>;
        })}
      </div>
    </div>;
  }
}

IssuesList.propTypes = {
  issues: PropTypes.array,
  intakeData: PropTypes.object,
  formType: PropTypes.string,
  onClickIssueAction: PropTypes.func,
  withdrawReview: PropTypes.bool,
  featureToggles: PropTypes.object
};
