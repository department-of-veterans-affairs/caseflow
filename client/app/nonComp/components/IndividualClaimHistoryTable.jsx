import React from 'react';
import QueueTable from '../../queue/QueueTable';
import dummyData from 'test/data/nonComp/individualClaimHistoryData';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';
const IndividualClaimHistoryTable = () => {

  const processDate = (date) => date;

  const formatDecisionDate = (date) => (new Date(date).toLocaleDateString());

  const ClaimCreatedFragment = () => {
    return <React.Fragment>Claim created.</React.Fragment>;
  };

  const ClaimInProgressFragment = () => {
    return <React.Fragment>Claim can be processed.</React.Fragment>;
  };

  const ClaimIncompleteFragment = () => {
    return <React.Fragment>Claim cannot be processed until decision date is entered.</React.Fragment>;
  };

  const ClaimClosedFragment = (details) => {
    return <React.Fragment>
      Claim closed.<br />
      <b>Claim decision date: </b>{formatDecisionDate(details.decisionDate)}
    </React.Fragment>;
  };

  const CancelledTaskFragment = () => {
    return <React.Fragment>
      Claim closed.
    </React.Fragment>;
  };

  const AddedIssueFragment = (details) => {
    return <React.Fragment>
      <b>Benefit type: </b>{BENEFIT_TYPES[details.benefitType]}<br />
      <b>Issue type: </b>{details.issueType}<br />
      <b>Issue description: </b>{details.issueDescription}<br />
    </React.Fragment>;
  };

  const AddedIssueWithDateFragment = (details) => {
    return <React.Fragment>
      <AddedIssueFragment {...details} />
      <b>Decision date: </b>{formatDecisionDate(details.decisionDate)}<br />
    </React.Fragment>;
  };

  const AddedIssueWithNoDateFragment = (details) => {
    return <React.Fragment>
      <AddedIssueFragment {...details} />
      <b>Decision date: </b>No decision date<br />
    </React.Fragment>;
  };
  const CompletedDispositionFragment = (details) => {
    return <React.Fragment>
      <AddedIssueWithDateFragment {...details} />
      <b>Disposition: </b>{details.disposition}<br />
      <b>Decision description: </b>{details.decisionDescription}<br />
    </React.Fragment>;
  };

  const RemovedIssueFragment = (details) => {
    return <React.Fragment>
      <AddedIssueWithDateFragment {...details} />
      <b>Removed issue date: </b>{formatDecisionDate(details.eventDate)}
    </React.Fragment>;
  };
  const WithdrewIssueFragment = (details) => {
    return <React.Fragment>
      <AddedIssueWithDateFragment {...details} />
      <b>Withdrawal request date: </b>{formatDecisionDate(details.withdrawalRequestDate)}<br />
    </React.Fragment>;
  };

  const AddedDecisionDateFragment = (details) => {
    return <React.Fragment>
      <AddedIssueWithDateFragment {...details} />
    </React.Fragment>;
  };

  const DetailsFragment = (row) => {
    let component = null;

    const { readableEventType, details } = row;

    details.eventDate = row.eventDate;

    switch (readableEventType) {
    case 'Claim created':
      component = <ClaimCreatedFragment />;
      break;
    case 'Claim closed':
      component = <ClaimClosedFragment {...details} />;
      break;
    case 'Completed disposition':
      component = <CompletedDispositionFragment {...details} />;
      break;
    case 'Claim status - In Progress':
      component = <ClaimInProgressFragment />;
      break;
    case 'Claim status - Incomplete':
      component = <ClaimIncompleteFragment />;
      break;
    case 'Added issue':
      component = <AddedIssueWithDateFragment {...details} />;
      break;
    case 'Added issue - No decision date':
      component = <AddedIssueWithNoDateFragment {...details} />;
      break;
    case 'Added decision date':
      component = <AddedDecisionDateFragment {...details} />;
      break;
    case 'Withdrew issue':
      component = <WithdrewIssueFragment {...details} />;
      break;
    case 'Removed issue':
      component = <RemovedIssueFragment {...details} />;
      break;
    case 'Cancelled task':
      component = <CancelledTaskFragment />;
      break;
    default:
      return null;
    }

    return <p>
      {component}
    </p>;
  };

  const columns = [
    { name: 'eventDate',
      header: 'Date and Time',
      valueFunction: (row) => processDate(row.eventDate),
      getSortValue: (row) => processDate(row.eventDate),
    },
    { name: 'eventUser',
      columnName: 'eventUser',
      header: 'User',
      valueName: 'User',
      valueFunction: (row) => row.eventUser,
      enableFilter: true,
      tableData: dummyData,
      anyFiltersAreSet: true,
      label: 'Filter by User',
      getSortValue: (row) => row.eventUser },
    { columnName: 'readableEventType',
      name: 'Activity',
      header: 'Activity',
      valueName: 'Activity',
      valueFunction: (row) => row.readableEventType,
      enableFilter: true,
      tableData: dummyData,
      anyFiltersAreSet: true,
      label: 'Filter by Activity',
      getSortValue: (row) => row.readableEventType },
    { name: 'details',
      header: 'Details',
      valueFunction: (row) => <DetailsFragment {...row} /> },
  ];

  return <QueueTable
    id="individual_claim_history_table"
    columns={columns}
    rowObjects={dummyData}
    summary="Individual claim history"
    getKeyForRow={(_rowNumber, event) => event.id}
    enablePagination
    useTaskPagesApi={false}
    defaultSort= {{
      sortColName: 'eventDate',
      sortAscending: false
    }} />;

};

export default IndividualClaimHistoryTable;
