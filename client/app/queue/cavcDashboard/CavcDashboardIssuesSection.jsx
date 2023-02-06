import React, { useState } from 'react';
import { css } from 'glamor';

import { LABELS } from './cavcDashboardConstants';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import PropTypes from 'prop-types';
import Dropdown from '../../components/Dropdown';

const singleIssueStyling = css({
  width: '75%',
  marginBottom: '1.5em !important',
  display: 'flex',
  justifyContent: 'space-between',
  '@media(max-width: 1200px)': { width: '100%' },
  '@media(max-width: 829px)': {
    flexDirection: 'column'
  }
});

const issueContentStyling = css({
  marginBottom: '0.3em'
});

const headerStyling = css({
  display: 'flex',
  justifyContent: 'space-around',
  marginBottom: '0'
});

export const CavcDashboardIssue = (props) => {
  const [disposition, setDisposition] = useState('Select');
  const { issue, index, dispositions } = props;

  return (
    <li key={index}>
      <div {...singleIssueStyling}>
        <div >
          <div {...issueContentStyling}>
            <strong> Benefit type: </strong> {BENEFIT_TYPES[issue.benefit_type]}
          </div>
          <div {...issueContentStyling}>
            <strong>Issue: </strong> {issue.decision_review_type} - {issue.contested_issue_description}
          </div>
        </div>
        <div>
          <Dropdown
            name={`issue-dispositions-${index}`}
            label="Dispositions"
            value={disposition}
            hideLabel
            options={dispositions}
            defaultText="Select"
            onChange={(option) => setDisposition(option)}
          />
        </div>
      </div>
    </li>
  );
};

export const CavcDashboardIssuesSection = (props) => {
  const { requestIssues } = props;
  const Issues = requestIssues.source_request_issues;

  return (
    <div>
      <strong {...headerStyling}>
        <span>{LABELS.CAVC_DASHBOARD_ISSUES}</span>
        <span>{LABELS.CAVC_DASHBOARD_DISPOSITIONS}</span>
      </strong>
      <hr />
      <ol>
        {Issues.map((issue, i) => {

          return (
            <React.Fragment key={i}>
              <CavcDashboardIssue issue={issue} index={i} dispositions={requestIssues.cavc_dashboard_dispositions} />
            </React.Fragment>
          );
        })}
      </ol>
    </div>
  );
};

CavcDashboardIssue.propTypes = {
  index: PropTypes.number,
  issue: PropTypes.shape({
    benefit_type: PropTypes.string,
    decision_review_type: PropTypes.string,
    contested_issue_description: PropTypes.string,
  }),
  dispositions: PropTypes.array,
};

CavcDashboardIssuesSection.propTypes = {
  requestIssues: PropTypes.object,
};

