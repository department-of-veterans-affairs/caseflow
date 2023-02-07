import React from 'react';

import { LABELS } from './cavcDashboardConstants';
import Table from '../../components/Table';
import PropTypes from 'prop-types';
import Dropdown from '../../components/Dropdown';

export const CavcDashboardIssuesTable = (props) => {
  const { requestIssues } = props;
  const Issues = requestIssues.source_request_issues;
  const Disposition = requestIssues.cavc_dashboard_dispositions;

  const CavcDashboardIssuesColumns = [
    {
      header: LABELS.CAVC_DASHBOARD_ISSUES,
      valueName: 'Issues'
    },
    {
      header: LABELS.CAVC_DASHBOARD_DISPOSITIONS,
      valueName: 'Dispositions'
    }
  ];

  const CavcDashboardIssuesRows = Issues.map((issue, i) => ({
    Issues: [<ol><li key = {i}><div><strong>Benefit Type: </strong>{issue.benefit_type} <br /> <strong>Issue: </strong>{issue.decision_review_type} - {issue.contested_issue_description}</div></li></ol>],
    Dispositions: [<Dropdown name={`issue-dispositions-${i}`}
      label="Dispositions"
      hideLabel
      value="Select"
      options={Disposition}
      defaultText="Select"
      onChange={(option) => (option)} />
    ] }));

  return (
    <Table
      columns={CavcDashboardIssuesColumns}
      rowObjects={CavcDashboardIssuesRows}
      getKeyForRow={(index) => index}
      {...props}
    />
  );

};

CavcDashboardIssuesTable.propTypes = {
  requestIssues: PropTypes.object,
};

