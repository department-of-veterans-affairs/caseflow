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

  return (
    <li key={index}>
      <div {...singleIssueStyling}>
        <div>
          <div>
            <strong> Benefit type: </strong> {[issue.benefit_type]}
          </div>
          <div>
            <strong>Issue: </strong> {issue.issue_category}
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

export const CavcDashboardRequestIssue = (props) => {
  const [disposition, setDisposition] = useState('Select');
  const { issue, index, dispositions } = props;

  return (
    <li key={index}>
      <div {...singleIssueStyling}>
        <div>
          <div>
            <strong> Benefit type: </strong> {[issue.benefit_type]}
          </div>
          <div>
            <strong>Issue: </strong> {issue.decision_review_type} - {issue.contested_issue_description}
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
  const Issues = remand.source_request_issues;
  const CavcIssues = remand.cavc_dashboard_issues;
  const Dispositions = remand.cavc_dashboard_dispositions;

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
              <CavcDashboardRequestIssue issue={issue} index={i} dispositions={Dispositions} />
            </React.Fragment>
          );
        })}
        {CavcIssues.map((CavcIssue, i) => {

          return (
            <React.Fragment key={i}>
              <CavcDashboardIssue issue={CavcIssue} index={i} dispositions={Dispositions} />
            </React.Fragment>
          );
        })}
      </ol>
    </div>
  );
};

CavcDashboardRequestIssue.propTypes = {
  index: PropTypes.number,
  issue: PropTypes.shape({
    benefit_type: PropTypes.string,
    decision_review_type: PropTypes.string,
    contested_issue_description: PropTypes.string,
  }),
  dispositions: PropTypes.array,
};

CavcDashboardIssue.propTypes = {
  index: PropTypes.number,
  issue: PropTypes.shape({
    benefit_type: PropTypes.string,
    issue_category: PropTypes.string,
  }),
  dispositions: PropTypes.array,
};

CavcDashboardIssuesSection.propTypes = {
  remand: PropTypes.object,
};

