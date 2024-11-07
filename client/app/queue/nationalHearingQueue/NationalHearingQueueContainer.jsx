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
      header: 'Docket Number',
      align: 'left',
      valueFunction: (row) => row.appeal.docketNumber
    }
  ];

  // "Borrowing" these from the decision review queues
  const queryParams = new URLSearchParams(window.location.search);
  const currentTabName = queryParams.get(QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM) || 'all';
  const findTab = RECOGNIZED_TABS.findIndex((tabName) => tabName === currentTabName);
  const getTabByIndex = findTab === -1 ? 0 : findTab;
  const getParamsFilter = queryParams.getAll(`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`);
  const tabPaginationOptions = {
    [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM),
    [QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM),
    [`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`]: getParamsFilter,
  };

  const generateTabs = () => RECOGNIZED_TABS.map((tabName) => {
    return {
      label: StringUtil.titleCase(tabName),
      page: <>
        <div>All cases owned by the National Hearings Scheduling team.</div><br />
        <QueueTable
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
          tabPaginationOptions={tabPaginationOptions}

          // These are new and I don't know what they're for yet
          // useReduxCache={this.props.useReduxCache}
          // reduxCache={this.props.queueTableResponseCache}
          // updateReduxCache={this.props.updateQueueTableCache}
        />
      </>
    };
  });

  // "Borrowing" this from the DR queue as well
  const resetPageNumberOnTabChange = (value) => {
    if (value !== getTabByIndex) {
      tabPaginationOptions.page = 0;
    }
  };

  return (<>
    <h1>Testing NHQ</h1>

    { /* Cutoff date component(s) goes here. */ }

    <TabWindow
      name="nhq-tabwindow"
      tabs={generateTabs()}
      defaultPage={getTabByIndex || 0}
      onChange={((value) => resetPageNumberOnTabChange(value))}
    />
  </>);
};

export default NationalHearingQueueContainer;
