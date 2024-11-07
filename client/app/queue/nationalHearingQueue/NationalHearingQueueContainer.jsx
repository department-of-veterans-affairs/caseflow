import React from 'react';

import QueueTable from '../QueueTable';

const NationalHearingQueueContainer = () => {

  const getTableColumns = () => [
    {
      header: 'Priority Number',
      align: 'left',
      valueFunction: (row) => row.priorityQueueNumber
    },
    {
      header: 'Appeal ID',
      align: 'left',
      valueFunction: (row) => row.appealId
    },
    {
      header: 'Appeal Type',
      align: 'left',
      valueFunction: (row) => row.appealType
    },
    {
      header: 'Docker Number',
      align: 'left',
      valueFunction: (row) => row.appeal.docketNumber
    }
  ];

  return (<>
    <h1>Testing NHQ</h1>

    <QueueTable
      columns={getTableColumns()}
      rowObjects={[]}
      getKeyForRow={(row, object) => object.task_id}
      enablePagination
      // onHistoryUpdate={this.props.onHistoryUpdate}
      // preserveFilter={this.props.preserveQueueFilter}
      rowClassNames={() => 'borderless'}
      taskPagesApiEndpoint="/national_hearing_queue?tab=all"
      useTaskPagesApi
      tabPaginationOptions={{}}
    // useReduxCache={this.props.useReduxCache}
    // reduxCache={this.props.queueTableResponseCache}
    // updateReduxCache={this.props.updateQueueTableCache}
    />
  </>);
};

export default NationalHearingQueueContainer;
