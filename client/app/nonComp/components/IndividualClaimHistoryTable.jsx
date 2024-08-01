import React, { useState } from 'react';
import { css } from 'glamor';
import QueueTable from '../../queue/QueueTable';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';
import { formatDateStr } from 'app/util/DateUtil';
import PropTypes from 'prop-types';
import StringUtil from 'app/util/StringUtil';
import _ from 'lodash';

const { capitalizeFirst } = StringUtil;

const IndividualClaimHistoryTable = (props) => {

  const { eventRows } = props;

  const processEventDate = (date) => {
    return new Date(date).toLocaleString('en-US', {
      hour12: false,
      day: '2-digit',
      year: 'numeric',
      month: '2-digit',
      hour: '2-digit',
      minute: '2-digit' });
  };

  const formatDecisionDate = (date) => {
    if (date) {
      return formatDateStr(date);
    }

    return 'No decision date';
  };

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
      <b>Claim decision date: </b>{formatDecisionDate(details.dispositionDate)}
    </React.Fragment>;
  };

  const AddedIssueFragment = (details) => {
    return <React.Fragment>
      <b>Benefit type: </b>{BENEFIT_TYPES[details.benefitType]}<br />
      <b>Issue type: </b>{details.issueType}<br />
      <b>Issue description: </b>{details.issueDescription}<br />
    </React.Fragment>;
  };

  const RequestedIssueFragment = (details) => {
    return <React.Fragment>
      <b>Benefit type: </b>{BENEFIT_TYPES[details.benefitType]}<br />
      <b>Issue type: </b>{details.newIssueType}<br />
      <b>Issue description: </b>{details.newIssueDescription}<br />
      <b>Decision date: </b>{formatDecisionDate(details.newDecisionDate)}<br />
      <b>{capitalizeFirst(details.requestType)} request reason: </b>{details.modificationRequestReason}<br />
    </React.Fragment>;
  };

  const WithdrawalRequestedIssueFormat = (details) => {
    return <>
      <RequestedIssueFragment {...details} />
      <b>Withdrawal request date: </b>{formatDecisionDate(details.issueModificationRequestWithdrawalDate)}<br />
    </>;
  };

  const RequestedIssueModificationFragment = (details) => {
    return <React.Fragment>
      <b>Benefit type: </b>{BENEFIT_TYPES[details.benefitType]}<br />
      <b>Current issue type: </b>{details.newIssueType}<br />
      <b>Current issue description: </b>{details.newIssueDescription}<br />
      <b>Current Decision date: </b>{formatDecisionDate(details.newDecisionDate)}<br />
      <b>New issue type: </b>{details.newIssueType}<br />
      <b>New issue description: </b>{details.newIssueDescription}<br />
      <b>New Decision date: </b>{formatDecisionDate(details.newDecisionDate)}<br />
      <b>{capitalizeFirst(details.requestType)} request reason: </b>{details.modificationRequestReason}<br />
    </React.Fragment>;
  };

  const RemoveOriginalIssueFragment = (details) => {
    return ['addition', 'modification', 'removal', 'withdrawal'].includes(details.requestType) ? <React.Fragment>
      <b>Remove original issue: </b>{details.removeOriginalIssue ? 'Yes' : 'No' }<br />
    </React.Fragment> : <></>;
  };

  const RequestedIssueDecisionFragement = (details) => {
    return <React.Fragment>
      <b>Request Decision: </b>{details.issueModificationRequestStatus}<br />
      <RemoveOriginalIssueFragment {...details} />
      <b>Request originated by: </b>{details.requestor}<br />
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

  const RejectedRequestedIssueModificationFragment = (details) => {
    return <React.Fragment>
      <b>Benefit type: </b>{BENEFIT_TYPES[details.benefitType]}<br />
      <b>Issue type: </b>{details.newIssueType}<br />
      <b>Issue description: </b>{details.newIssueDescription}<br />
      <b>Decision date: </b>{formatDecisionDate(details.newDecisionDate)}<br />
      <b>{capitalizeFirst(details.requestType)} request reason: </b>{details.modificationRequestReason}<br />
    </React.Fragment>;
  };

  const EditedRequestedIssueModificationFragment = (details) => {
    return <React.Fragment>
      <b>Benefit type: </b>{BENEFIT_TYPES[details.benefitType]}<br />
      <b>Issue type: </b>{details.newIssueType}<br />
      <b>Issue description: </b>{details.newIssueDescription}<br />
      <b>Decision date: </b>{formatDecisionDate(details.newDecisionDate)}<br />
      <b>{capitalizeFirst(details.requestType)} request reason: </b>{details.modificationRequestReason}<br />
      <b>{capitalizeFirst(details.requestType)} request date: </b>{formatDecisionDate(details.issueModificationRequestWithdrawalDate)}<br />
    </React.Fragment>;
  };

  const ApprovalRequestedIssueModificationFragment = (details) => {
    return <React.Fragment>
      <b>Benefit type: </b>{BENEFIT_TYPES[details.benefitType]}<br />
      <b>Current issue type: </b>{details.newIssueType}<br />
      <b>Current issue description: </b>{details.newIssueDescription}<br />
      <b>Current Decision date: </b>{formatDecisionDate(details.newDecisionDate)}<br />
      <b>New issue type: </b>{details.newIssueType}<br />
      <b>New issue description: </b>{details.newIssueDescription}<br />
      <b>New Decision date: </b>{formatDecisionDate(details.newDecisionDate)}<br />
      <b>{capitalizeFirst(details.requestType)} request reason: </b>{details.modificationRequestReason}<br />
    </React.Fragment>;
  };

  const OriginalDetailsFragments = (row) => {
    const { readableEventType, details, modificationRequestDetails } = row;

    const requestDetails = { ...modificationRequestDetails, requestType: row.requestType };
    const requestModificationDetails = { ...details, ...requestDetails };
    let component = null;
    const [isOpen, setIsOpen] = useState(false);

    const toggle = () => {
      setIsOpen((isOpen) => !isOpen);
    };

    switch (readableEventType) {
    case `Rejection of request - issue ${row.requestType}`:
      component = <RejectedRequestedIssueModificationFragment {...requestModificationDetails} />;
      break;
    case `Edit of request - issue ${row.requestType}`:
      component = <EditedRequestedIssueModificationFragment {...requestModificationDetails} />;
      break;
    case `Approval of request - issue ${row.requestType}`:
      component = <ApprovalRequestedIssueModificationFragment {...requestModificationDetails} />;
      break;
    default:
      return null;
    }

    return (
      <div>
        <div style={{ marginBottom: '15px' }}>
          <a onClick={toggle} style={{ cursor: 'pointer' }}>{`${isOpen ? 'Hide' : 'View' } original request`}</a>
        </div>
        {isOpen &&
          <div>
            {component}
          </div>}
      </div>
    );
  };

  const DetailsFragment = (row) => {

    let component = null;

    const { readableEventType, details, modificationRequestDetails } = row;

    const detailsExtended = { ...details, eventDate: row.eventDate, eventType: row.eventType };

    const requestDetails = { ...modificationRequestDetails, requestType: row.requestType };
    const RequestIssueModificationDetails = { ...requestDetails, ...detailsExtended };

    switch (readableEventType) {
    case 'Claim created':
      component = <ClaimCreatedFragment />;
      break;
    case 'Claim closed':
      component = <ClaimClosedFragment {...detailsExtended} />;
      break;
    case 'Completed disposition':
      component = <CompletedDispositionFragment {...detailsExtended} />;
      break;
    case 'Claim status - In progress':
      component = <ClaimInProgressFragment />;
      break;
    case 'Claim status - Incomplete':
      component = <ClaimIncompleteFragment />;
      break;
    case 'Added issue':
      component = <AddedIssueWithDateFragment {...detailsExtended} />;
      break;
    case 'Added issue - No decision date':
      component = <AddedIssueWithNoDateFragment {...detailsExtended} />;
      break;
    case 'Added decision date':
      component = <AddedDecisionDateFragment {...detailsExtended} />;
      break;
    case 'Withdrew issue':
      component = <WithdrewIssueFragment {...detailsExtended} />;
      break;
    case 'Removed issue':
      component = <RemovedIssueFragment {...detailsExtended} />;
      break;
    case 'Cancellation of request':
      component = <RequestedIssueFragment {...requestDetails} />;
      break;
    case 'Requested issue removal':
      component = <RequestedIssueFragment {...requestDetails} />;
      break;
    case "Requested issue modification":
      component = <RequestedIssueModificationFragment {...requestDetails} />;
      break;
    case 'Requested issue addition':
      component = <RequestedIssueFragment {...requestDetails} />;
      break;
    case 'Requested issue withdrawal':
      component = <WithdrawalRequestedIssueFormat {...requestDetails} />;
      break;
    case `Approval of request - issue ${row.requestType}`:
      component = <RequestedIssueDecisionFragement {...RequestIssueModificationDetails} />;
      break;
    case `Edit of request - issue ${row.requestType}`:
      component = <RequestedIssueDecisionFragement {...RequestIssueModificationDetails} />;
      break;
    case `Rejection of request - issue ${row.requestType}`:
      component = <RequestedIssueDecisionFragement {...RequestIssueModificationDetails} />;
      break;
    default:
      return null;
    }

    const chunk = [
      'request_approved',
      'request_edited',
      'request_denied'
    ];

    return (
      <div>
        <p>{component}</p>
        { chunk.includes(RequestIssueModificationDetails.eventType) ? <OriginalDetailsFragments {...row} /> : null }
      </div>
    );
  };

  const dateSort = (row) => {
    let date = new Date(row.eventDate);

    // cheat the dates for claim created and claim closed
    const eventOrder = {
      'Claim created': -Infinity,
      'Claim closed': Infinity,
    };

    if (row.readableEventType in eventOrder) {
      return eventOrder[row.readableEventType];
    }

    return date;
  };

  const columns = [
    { name: 'eventDate',
      header: 'Date and Time',
      valueFunction: (row) => processEventDate(row.eventDate),
      getSortValue: (row) => dateSort(row),
    },
    { name: 'eventUser',
      columnName: 'eventUser',
      header: 'User',
      valueName: 'User',
      valueFunction: (row) => row.eventUser,
      enableFilter: true,
      tableData: eventRows,
      anyFiltersAreSet: true,
      label: 'Filter by User',
      enableFilterTextTransform: false,
      getSortValue: (row) => row.eventUser },
    { columnName: 'readableEventType',
      name: 'Activity',
      header: 'Activity',
      valueName: 'Activity',
      valueFunction: (row) => row.readableEventType,
      enableFilter: true,
      enableFilterTextTransform: false,
      tableData: eventRows,
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
    rowObjects={eventRows}
    summary="Individual claim history"
    getKeyForRow={(_rowNumber, event) => event.id}
    enablePagination
    useTaskPagesApi={false}
    defaultSort= {{
      sortColName: 'eventDate',
      sortAscending: false
    }}
    className="claim-history-table-border-fix" />;

};

IndividualClaimHistoryTable.propTypes = {
  eventRows: PropTypes.array
};

export default IndividualClaimHistoryTable;
