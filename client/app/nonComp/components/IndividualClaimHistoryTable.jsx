import React from 'react';
import { useSelector } from 'react-redux';
import NonCompLayout from '../components/NonCompLayout';
import Link from 'app/components/Link';
import styled from 'styled-components';
import QueueTable from '../../queue/QueueTable';

const IndividualClaimHistoryTable = () => {

  // const task = useSelector(
  //   (state) => state.nonComp.task
  // );

  const processDate = (date) => date;

  const claimCreatedFragment = () => {
    return <React.Fragment>Claim created</React.Fragment>;
  };

  const claimInProgressFragment = () => {
    return <React.Fragment>Claim can be processed.</React.Fragment>;
  };

  const claimIncompleteFragment = () => {
    return <React.Fragment>Claim cannot be processed until decision date is entered.</React.Fragment>;
  };

  const claimClosedFragment = (details) => {
    return <React.Fragment>
      Claim closed.<br />
      <b>Claim decision date: </b>{details.decisionDate}
    </React.Fragment>;
  };

  const completedDispositionFragment = (details) => {
    return <React.Fragment>
      <b>Benefit type: </b>{details.benefitType}<br />
      <b>Issue type: </b>{details.issueType}<br />
      <b>Issue description: </b>{details.issueDescription}<br />
      <b>Decision date: </b>{details.decisionDate}<br />
      <b>Disposition: </b>{details.disposition}<br />
      <b>Decision description: </b>{details.decisionDescription}<br />
    </React.Fragment>;
  };

  const addedIssueFragment = (details) => {
    return <React.Fragment>
      <b>Benefit type: </b>{details.benefitType}<br />
      <b>Issue type: </b>{details.issueType}<br />
      <b>Issue description: </b>{details.issueDescription}<br />
      <b>Decision date: </b>{details.decisionDate}<br />
    </React.Fragment>;
  };

  const withdrewIssueFragment = (details) => {
    return <React.Fragment>
      <b>Benefit type: </b>{details.benefitType}<br />
      <b>Issue type: </b>{details.issueType}<br />
      <b>Issue description: </b>{details.issueDescription}<br />
      <b>Decision date: </b>{details.decisionDate}<br />
      <b>Withdrawal request date: </b>{details.withdrawalRequestDate}<br />
    </React.Fragment>;
  };

  const detailsFragment = (eventType, details) => {
    switch (eventType) {
    case 'Claim created':
      return claimCreatedFragment();
    case 'Claim closed':
      return claimClosedFragment(details);
    case 'Completed disposition':
      return completedDispositionFragment(details);
    case 'Claim status - In progress':
      return claimInProgressFragment();
    case 'Claim status - Incomplete':
      return claimIncompleteFragment();
    case 'Added issue':
      return addedIssueFragment(details);
    case 'Added issue - No decision date':
      return addedIssueFragment(details);
    case 'Withdrew issue':
      return withdrewIssueFragment(details);
    default:
      return null;
    }

    // return
  };

  const dummyData = [
    {
      eventDate: '07/05/23, 15:00',
      eventUser: 'System',
      readableEventType: 'Claim closed',
      details: {
        decisionDate: '07/05/23'
      }
    },
    {
      eventDate: '07/05/23, 15:00',
      eventUser: 'System',
      readableEventType: 'Claim created',
      details: {
        decisionDate: '07/05/23'
      }
    },
    {
      eventDate: '07/05/23, 15:00',
      eventUser: 'J. Dudifer',
      readableEventType: 'Completed disposition',
      details: {
        benefitType: 'Veterans Health Administration',
        issueType: 'Beneficiary Travel',
        issueDescription: 'Any notes will display here',
        decisionDate: '05/31/2023',
        disposition: 'Granted',
        decisionDescription: 'Any notes from decision will display here'
      }
    },
    {
      eventDate: '07/05/23, 15:00',
      eventUser: 'System',
      readableEventType: 'Claim status - In progress',
      details: {
        decisionDate: '07/05/23'
      }
    },
    {
      eventDate: '07/05/23, 15:00',
      eventUser: 'System',
      readableEventType: 'Claim status - Incomplete',
      details: {
        decisionDate: ''
      }
    },
    {
      eventDate: '07/05/23, 15:00',
      eventUser: 'System',
      readableEventType: 'Added issue',
      details: {
        benefitType: 'Veterans Health Administration',
        issueType: 'Beneficiary Travel',
        issueDescription: 'Any notes will display here',
        decisionDate: '05/31/2023',
        disposition: 'Granted',
        decisionDescription: 'Any notes from decision will display here'
      }
    },
    {
      eventDate: '07/05/23, 15:00',
      eventUser: 'System',
      readableEventType: 'Added issue - No decision date',
      details: {
        benefitType: 'Veterans Health Administration',
        issueType: 'Beneficiary Travel',
        issueDescription: 'Any notes will display here',
        decisionDate: '',
        disposition: 'Granted',
        decisionDescription: 'Any notes from decision will display here'
      }
    },
    {
      eventDate: '07/05/23, 15:00',
      eventUser: 'System',
      readableEventType: 'Withdrew issue',
      details: {
        benefitType: 'Veterans Health Administration',
        issueType: 'Beneficiary Travel',
        issueDescription: 'Any notes will display here',
        decisionDate: '07/04/23',
        withdrawalRequestDate: '07/05/23',
      }
    },
  ];

  return <QueueTable
    id="individual_claim_history_table"
    columns={[
      { columnName: 'eventDate', header: 'Date and Time', valueFunction: (row) => processDate(row.eventDate) },
      { columnName: 'eventUser', header: 'User', valueName: 'eventUser', enableFilter: true },
      { columnName: 'eventType', header: 'Activity', valueName: 'readableEventType', enableFilter: true },
      { columnName: 'details', header: 'Details', valueFunction: (row) => detailsFragment(row.readableEventType, row.details) },
    ]}
    rowObjects={dummyData}
    summary="Individual claim history"
    slowReRendersAreOk
    enablePagination />;

};

export default IndividualClaimHistoryTable;
