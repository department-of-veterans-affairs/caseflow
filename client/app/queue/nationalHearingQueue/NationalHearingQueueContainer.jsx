import React from 'react';

import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import StringUtil from '../../util/StringUtil';

import QueueTable from '../QueueTable';
import TabWindow from '../../components/TabWindow';

const NationalHearingQueueContainer = () => {
  const RECOGNIZED_TABS = ['all', 'unassigned', 'on_hold', 'assigned'];

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

  // "Borrowing" these from the decision review queues
  const queryParams = new URLSearchParams(window.location.search);
  const currentTabName = queryParams.get(QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM) || 'all';
  const findTab = RECOGNIZED_TABS.findIndex((tabName) => tabName === currentTabName);
  const getTabByIndex = findTab === -1 ? 0 : findTab;

  const generateTabs = () => RECOGNIZED_TABS.map((tabName) => {
    return {
      label: StringUtil.titleCase(tabName),
      page: <QueueTable
        // Eventually these columns need to differ between tabs
        columns={getTableColumns()}
        rowObjects={[]}
        getKeyForRow={(row, object) => object.task_id}
        enablePagination
        // onHistoryUpdate={this.props.onHistoryUpdate}
        // preserveFilter={this.props.preserveQueueFilter}
        rowClassNames={() => 'borderless'}
        taskPagesApiEndpoint={`/national_hearing_queue?tab=${tabName}`}
        useTaskPagesApi
        tabPaginationOptions={{}}

        // These are new and I don't know what they're for yet
        // useReduxCache={this.props.useReduxCache}
        // reduxCache={this.props.queueTableResponseCache}
        // updateReduxCache={this.props.updateQueueTableCache}
      />
    };
  });

  return (<>
    <h1>Testing NHQ</h1>

    <TabWindow
      name="nhq-tabwindow"
      tabs={generateTabs()}
      defaultPage={getTabByIndex || 0}
    />
  </>);
};

export default NationalHearingQueueContainer;
