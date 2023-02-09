import React, { useState } from 'react';
import { css } from 'glamor';

import { LABELS } from './cavcDashboardConstants';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../components/SearchableDropdown';

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

export const CavcDashboardIssue = (props) => {
  const [disposition, setDisposition] = useState('Select');
  const { issue, index, dispositions } = props;
  let IssueType = {};

  if (issue.decision_review_type) {
    IssueType = `${issue.decision_review_type} - ${issue.contested_issue_description}`;
  } else {
    IssueType = issue.issue_category;
  }

  return (
    <li key={index}>
      <div {...singleIssueStyling}>
        <div>
          <div>
            <strong> Benefit type: </strong> {[issue.benefit_type]}
          </div>
          <div>
            <strong>Issue: </strong> {IssueType}
          </div>
        </div>
        <div>
          <SearchableDropdown
            name={`issue-dispositions-${index}`}
            label="Dispositions"
            value={disposition}
            searchable
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
  const { remand } = props;
  let Issues = remand.source_request_issues;
  const CavcIssues = remand.cavc_dashboard_issues;
  const Dispositions = remand.cavc_dashboard_dispositions;

  if (CavcIssues.length !== 0 && Issues.length !== 0) {
    CavcIssues.map((CavcIssue) => {
      return Issues.push(CavcIssue);
    });
  } else if (CavcIssues.length !== 0) {
    Issues = CavcIssues;
  }

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
        {Issues.map((issue, i) => {

          return (
            <React.Fragment key={i}>
              <CavcDashboardIssue issue={issue} index={i} dispositions={Dispositions} />
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
  remand: PropTypes.object,
};

