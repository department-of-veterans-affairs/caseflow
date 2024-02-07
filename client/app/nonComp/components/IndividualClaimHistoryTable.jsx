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

  const detailsFragment = (details) => {
    return <React.Fragment>{details}</React.Fragment>;
  };

  return <QueueTable
    id="individual_claim_history_table"
    columns={[
      { columnName: 'eventDate', header: 'Date and Time', valueFunction: (row) => processDate(row.eventDate) },
      { columnName: 'eventUser', header: 'User', valueName: 'eventUser', enableFilter: true },
      { columnName: 'eventType', header: 'Activity', valueName: 'eventType', enableFilter: true },
      { columnName: 'details', header: 'Details', valueFunction: (row) => detailsFragment(row.details) },
    ]}
    rowObjects={[
      {
        eventDate: '07/05/23, 15:00',
        eventUser: 'System',
        eventType: 'Claim closed'
      },
      {
        eventDate: '07/05/23, 15:00',
        eventUser: 'J. Dudifer',
        eventType: 'Completed disposition'
      },
      {
        eventDate: '07/05/23, 15:00',
        eventUser: 'A. Duderino',
        eventType: 'Withdrew issue',
        details: 'withdrew asdf lorem blabla'
      },
    ]}
    summary="Individual claim history"
    slowReRendersAreOk
    enablePagination />;

};

export default IndividualClaimHistoryTable;
