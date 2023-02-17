import React, { useState } from 'react';
import { css } from 'glamor';

import { LABELS } from './cavcDashboardConstants';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../components/SearchableDropdown';
import CAVC_DASHBOARD_DISPOSITIONS from '../../../constants/CAVC_DASHBOARD_DISPOSITIONS.json';

const singleIssueStyling = css({
  marginBottom: '1.5em !important',
  display: 'grid',
  fontWeight: 'normal',
  gridTemplateColumns: '60% 40%',
  '@media(max-width: 1200px)': { width: '100%' },
  '@media(max-width: 829px)': {
    display: 'flex',
    flexDirection: 'column'
  }
});

const headerStyling = css({
  display: 'grid',
  gridTemplateColumns: '60% 40%',
  marginBottom: '0',
  paddingLeft: '21px'
});

const issueSectionStyling = css({
  marginTop: '1.5em'
});

const olStyling = css({
  fontWeight: 'bold',
});

const CavcDashboardIssue = (props) => {
  const { dispositions, issue, index } = props;
  const [disposition, setDisposition] = useState(dispositions.disposition || 'Select');

  const dispositionsOptions = Object.keys(CAVC_DASHBOARD_DISPOSITIONS)
  .map((value) => ({ value, "label": CAVC_DASHBOARD_DISPOSITIONS[value] }));

  let issueType = {};

  if (issue.decision_review_type) {
    issueType = `${issue.decision_review_type} - ${issue.contested_issue_description}`;
  } else {
    issueType = issue.issue_category;
  }

  return (
    <li key={index}>
      <div {...singleIssueStyling}>
        <div>
          <div>
            <strong> Benefit type: </strong> {[issue.benefit_type]}
          </div>
          <div>
            <strong>Issue: </strong> {issueType}
          </div>
        </div>
        <div>
          <SearchableDropdown
            name={`issue-dispositions-${index}`}
            label="Dispositions"
            value={disposition}
            searchable
            hideLabel
            options={dispositionsOptions}
            defaultText="Select"
            onChange={(option) => setDisposition(option)}
          />
        </div>
      </div>
    </li>
  );
};

const CavcDashboardIssuesSection = (props) => {
  const { dashboard } = props;
  const issues = dashboard.source_request_issues;
  const cavcIssues = dashboard.cavc_dashboard_issues;
  const dashboardDispositions = dashboard.cavc_dashboard_dispositions;

  return (
    <div {...issueSectionStyling}>
      <div>
        <strong {...headerStyling}>
          <span>{LABELS.CAVC_DASHBOARD_ISSUES}</span>
          <span>{LABELS.CAVC_DASHBOARD_DISPOSITIONS}</span>
        </strong>
        <hr />
      </div>
      <ol {...olStyling}>
        {issues.map((issue, i) => {

          return (
            <React.Fragment key={i}>
              <CavcDashboardIssue issue={issue} index={i} dispositions={dashboardDispositions} />
            </React.Fragment>
          );
        })}
        {cavcIssues.map((cavcIssue, i) => {

          return (
            <React.Fragment key={i}>
              <CavcDashboardIssue issue={cavcIssue} index={i} dispositions={dashboardDispositions} />
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
    issue_category: PropTypes.string,
  }),
  dispositions: PropTypes.array,
};

CavcDashboardIssuesSection.propTypes = {
  dashboard: PropTypes.object,
};

export default CavcDashboardIssuesSection;
