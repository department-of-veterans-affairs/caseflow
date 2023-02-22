import React, { useState } from 'react';
import { css } from 'glamor';

import { LABELS } from './cavcDashboardConstants';
import PropTypes from 'prop-types';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import COPY from '../../../COPY';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';

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
  marginBottom: '0'
});

const issueSectionStyling = css({
  marginTop: '1.5em'
});

const olStyling = css({
  fontWeight: 'bold',
  paddingLeft: '1em'
});

const CavcDashboardIssue = (props) => {
  const [disposition, setDisposition] = useState('Select');
  const {
    issue,
    index,
    dispositions,
    removeIssueHandler,
    addedIssueSection
  } = props;
  let issueType = {};

  if (issue.decision_review_type) {
    issueType = `${issue.decision_review_type} - ${issue.contested_issue_description}`;
  } else {
    issueType = addedIssueSection ? issue.issue_category.label : issue.issue_category;
  }

  const removeIssue = () => {
    removeIssueHandler(index);
  };

  return (
    <li key={index}>
      <div {...singleIssueStyling}>
        <div>
          <div>
            <strong> Benefit type: </strong> {BENEFIT_TYPES[issue.benefit_type]}
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
            options={dispositions}
            defaultText="Select"
            onChange={(option) => setDisposition(option)}
          />
        </div>
        <div />
        {addedIssueSection &&
          <Button
            type="button"
            name="Remove Issue Button"
            classNames={['cf-push-right', 'cf-btn-link']}
            onClick={removeIssue}
          >
            <i className="fa fa-trash-o" aria-hidden="true"></i>  { COPY.REMOVE_CAVC_DASHBOARD_ISSUE_BUTTON_TEXT }
          </Button>
        }
      </div>
    </li>
  );
};

const CavcDashboardIssuesSection = (props) => {
  const { dashboard, dashboardIndex, removeDashboardIssue } = props;
  const issues = dashboard.source_request_issues;
  const cavcIssues = dashboard.cavc_dashboard_issues;
  const dashboardDispositions = dashboard.cavc_dashboard_dispositions;

  // the handler is in this component because it needs the dashboardIndex prop that isn't passed down
  const removeIssueHandler = (issueIndex) => {
    removeDashboardIssue(dashboardIndex, issueIndex);
  };

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
      </ol>
      <br />
      {cavcIssues.length > 0 &&
        <>
          <div>
            <strong {...headerStyling}>
              <span>{LABELS.CAVC_DASHBOARD_ADDED_ISSUES}</span>
              <span>{LABELS.CAVC_DASHBOARD_DISPOSITIONS}</span>
            </strong>
            <hr />
          </div>
          <ol {...olStyling}>
            {cavcIssues.map((cavcIssue, i) => {

              return (
                <React.Fragment key={i}>
                  <CavcDashboardIssue
                    issue={cavcIssue}
                    index={i}
                    dispositions={dashboardDispositions}
                    removeIssueHandler={removeIssueHandler}
                    addedIssueSection
                  />
                </React.Fragment>
              );
            })}
          </ol>
        </>
      }
    </div>
  );
};

CavcDashboardIssue.propTypes = {
  index: PropTypes.number,
  issue: PropTypes.shape({
    benefit_type: PropTypes.string,
    decision_review_type: PropTypes.string,
    contested_issue_description: PropTypes.string,
    issue_category: PropTypes.oneOfType([PropTypes.string, PropTypes.object]),
  }),
  dispositions: PropTypes.array,
  removeIssueHandler: PropTypes.func,
  addedIssueSection: PropTypes.bool
};

CavcDashboardIssuesSection.propTypes = {
  dashboard: PropTypes.object,
  dashboardIndex: PropTypes.number,
  removeDashboardIssue: PropTypes.func,
};

export default CavcDashboardIssuesSection;
