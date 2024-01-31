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

  return <QueueTable
    id="individual_claim_history_table"
    columns={[
      { columnName: 'dateAndTime', header: 'Date and Time', valueFunction: () => 'date format func' },
      { columnName: 'user', header: 'User', valueName: 'user', enableFilter: true },
      { columnName: 'activity', header: 'Activity', valueName: 'activity', enableFilter: true },
      { columnName: 'details', header: 'Details', valueFunction: () => 'get and format details' },
    ]}
    rowObjects={[
      {
        user: 'System',
        activity: 'Claim closed'
      },
      {
        user: 'J. Dudifer',
        activity: 'Completed disposition'
      },
      {
        user: 'A. Duderino',
        activity: 'Withdrew issue'
      },
    ]}
    summary="Individual claim history"
    slowReRendersAreOk
    enablePagination />;

};

export default IndividualClaimHistoryTable;
