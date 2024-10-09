/* eslint-disable max-lines */
import React, { useState } from 'react';
import QueueTable from '../../queue/QueueTable';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';
import { formatDateStr } from 'app/util/DateUtil';
import PropTypes from 'prop-types';
import StringUtil from 'app/util/StringUtil';

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

  const ClaimPendingFragment = () => {
    return <React.Fragment>Claim cannot be processed until VHA admin reviews pending requests.</React.Fragment>;
  };

  const ClaimIncompleteFragment = () => {
    return <React.Fragment>Claim cannot be processed until decision date is entered.</React.Fragment>;
  };

  const benefitType = (details) => {
    return <>
      <b>Benefit type: </b>{BENEFIT_TYPES[details.benefitType]}<br />
    </>;
  };

  const ClaimClosedFragment = (details) => {
    const fragment = details.eventType === 'cancelled' ? <>
      Claim cancelled.
    </> : <>
        Claim closed.<br />
      <b>Claim decision date: </b>{formatDecisionDate(details.dispositionDate)}
    </>;

    return (
      <div>
        {fragment}
      </div>
    );
  };

  const AddedIssueFragment = (details) => {
    return <React.Fragment>
      { benefitType(details) }
      <b>Issue type: </b>{details.issueType}<br />
      <b>Issue description: </b>{details.issueDescription}<br />
    </React.Fragment>;
  };

  const RequestedIssueFragment = (details) => {
    return <React.Fragment>
      { benefitType(details) }
      <b>Issue type: </b>{details.newIssueType}<br />
      <b>Issue description: </b>{details.newIssueDescription}<br />
      <b>Decision date: </b>{formatDecisionDate(details.newDecisionDate)}<br />
      <b>{capitalizeFirst(details.requestType)} request reason: </b>{details.modificationRequestReason}<br />
    </React.Fragment>;
  };

  const WithdrawalRequestedIssueFragment = (details) => {
    return <>
      <RequestedIssueFragment {...details} />
      <b>Withdrawal request date: </b>{formatDecisionDate(details.issueModificationRequestWithdrawalDate)}<br />
    </>;
  };

  const formatLabel = (baseLabel, prefix) => {
    if (prefix) {
      return `${prefix} ${baseLabel.toLowerCase()}`;
    }

    return baseLabel;
  };

  const previousModificationFragment = (details, prefix) => {
    return <React.Fragment>
      <b>{formatLabel('Issue type:', prefix)} </b>{details.previousIssueType}<br />
      <b>{formatLabel('Issue description:', prefix)} </b>{details.previousIssueDescription}<br />
      <b>{formatLabel('Decision date:', prefix)} </b>{formatDecisionDate(details.previousDecisionDate)}<br />
      <b>{capitalizeFirst(details.requestType)} request reason: </b>{details.previousModificationRequestReason}<br />
    </React.Fragment>;
  };

  const RequestedIssueModificationFragment = (details) => {
    return <React.Fragment>
      { benefitType(details) }
      <b>Current issue type: </b>{details.issueType}<br />
      <b>Current issue description: </b>{details.issueDescription}<br />
      <b>Current decision date: </b>{formatDecisionDate(details.decisionDate)}<br />
      { previousModificationFragment(details, 'New') }
    </React.Fragment>;
  };

  const RemoveOriginalIssueFragment = (details) => {
    return <React.Fragment>
      <b>Remove original issue: </b>{details.removeOriginalIssue ? 'Yes' : 'No' }<br />
    </React.Fragment>;
  };

  const requestDecision = (details) => {
    return <React.Fragment>
      <b>Request decision: </b> {details.issueModificationRequestStatus === 'denied' ? 'Rejected' : 'Approved'} <br />
    </React.Fragment>;
  };

  const RequestedIssueDecisionFragment = (details) => {
    return <React.Fragment>
      {requestDecision(details)}
      { details.issueModificationRequestStatus === 'approved' && details.requestType === 'modification' ?
        <RemoveOriginalIssueFragment {...details} /> : null
      }
      { details.issueModificationRequestStatus === 'denied' ?
        <React.Fragment>
          <b>Reason for rejection: </b> {details.decisionReason} <br />
        </React.Fragment> : null
      }
      <b>Request originated by: </b>{details.requestor}<br />
    </React.Fragment>;
  };

  const modificationRequestReason = (details) => {
    return <React.Fragment>
      <b>New {details.requestType} request reason: </b>{details.modificationRequestReason}<br />
    </React.Fragment>;
  };

  const EditOfRequestIssueModification = (details) => {
    let component = null;

    switch (details.requestType) {
    case 'modification':
    case 'addition':
      component = <React.Fragment>
        <b>New issue type: </b>{details.newIssueType}<br />
        <b>New issue description: </b>{details.newIssueDescription}<br />
        <b>New decision date: </b>{formatDecisionDate(details.newDecisionDate)}<br />
        {modificationRequestReason(details)}
      </React.Fragment>;
      break;
    case 'removal':
      component = <React.Fragment>
        {modificationRequestReason(details)}
      </React.Fragment>;
      break;
    case 'withdrawal':
      component = <React.Fragment>
        {modificationRequestReason(details)}
        <b>New withdrawal request date: </b> {formatDecisionDate(details.issueModificationRequestWithdrawalDate)}<br />
      </React.Fragment>;
      break;
    default:
      return null;
    }

    return <React.Fragment>
      {component}
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

  const WithdrawnRequestedIssueModificationFragment = (details) => {
    return <React.Fragment>
      <PreviousFragmentWithBenefitType {...details} />
      <b>Withdrawal request date: </b> {formatDecisionDate(details.previousWithdrawalDate)}<br />
    </React.Fragment>;
  };

  const PreviousFragmentWithBenefitType = (details) => {
    return <React.Fragment>
      { benefitType(details) }
      { previousModificationFragment(details) }
    </React.Fragment>;
  };

  const OriginalRequestedIssueModificationFragment = (details) => {
    let component = null;

    switch (details.requestType) {
    case 'modification':
      component = <RequestedIssueModificationFragment {...details} />;
      break;
    case 'addition':
    case 'removal':
      component = <PreviousFragmentWithBenefitType {...details} />;
      break;
    case 'withdrawal':
      component = <WithdrawnRequestedIssueModificationFragment {...details} />;
      break;
    default:
      return null;
    }

    return (
      <div>
        {component}
      </div>
    );
  };

  const OriginalDetailsFragments = (row) => {
    const { details, modificationRequestDetails } = row;
    const requestModificationDetails = { ...details, ...modificationRequestDetails };

    const [isOpen, setIsOpen] = useState(false);

    const toggle = () => {
      setIsOpen(!isOpen);
    };

    return (
      <div>
        <div style={{ marginBottom: '15px' }}>
          <a onClick={toggle} style={{ cursor: 'pointer' }}>{`${isOpen ? 'Hide' : 'View' } original request`}</a>
        </div>
        {isOpen &&
          <div>
            <OriginalRequestedIssueModificationFragment {...requestModificationDetails} />
          </div>}
      </div>
    );
  };

  const DetailsFragment = (row) => {

    let component = null;
    const { readableEventType, details, modificationRequestDetails } = row;
    const detailsExtended = { ...details, eventDate: row.eventDate, eventType: row.eventType };
    const requestIssueModificationDetails = { ...modificationRequestDetails, ...detailsExtended };

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
    case 'Claim status - Pending':
      component = <ClaimPendingFragment />;
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
      component = <OriginalRequestedIssueModificationFragment {...requestIssueModificationDetails} />;
      break;
    case 'Requested issue modification':
      component = <RequestedIssueModificationFragment {...requestIssueModificationDetails} />;
      break;
    case 'Requested issue addition':
    case 'Requested issue removal':
      component = <RequestedIssueFragment {...requestIssueModificationDetails} />;
      break;
    case 'Requested issue withdrawal':
      component = <WithdrawalRequestedIssueFragment {...requestIssueModificationDetails} />;
      break;
    case `Edit of request - issue ${requestIssueModificationDetails.requestType}`:
      component = <EditOfRequestIssueModification {...requestIssueModificationDetails} />;
      break;
    case `Rejection of request - issue ${requestIssueModificationDetails.requestType}`:
    case `Approval of request - issue ${requestIssueModificationDetails.requestType}`:
      component = <RequestedIssueDecisionFragment {...requestIssueModificationDetails} />;
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
        { chunk.includes(requestIssueModificationDetails.eventType) ? <OriginalDetailsFragments {...row} /> : null }
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
/* eslint-enable max-lines */
