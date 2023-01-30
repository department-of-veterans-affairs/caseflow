import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import TabWindow from '../../components/TabWindow';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import COPY from '../../../COPY';
import TaskTableTab from './TaskTableTab';

class NonCompTabsUnconnected extends React.PureComponent {
  render = () => {
    const queryParams = new URLSearchParams(window.location.search);
    const currentTabName = queryParams.get(QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM) || 'in_progress';
    const defaultSortColumn = currentTabName === 'in_progress' ? 'daysWaitingColumn' : 'completedDateColumn';
    const tabPaginationOptions = {
      [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM),
      [QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM),
      [QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM) || 'desc',
      [QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM) ||
        defaultSortColumn,
      [`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`]: queryParams.getAll(
        `${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`
      ),
    };
    const tabArray = ['in_progress', 'completed'];
    // If additional tabs need to be added, include them in the array above
    // to be able to locate them by their index
    const findTab = tabArray.findIndex((tabName) => tabName === currentTabName);
    const getTabByIndex = findTab === -1 ? 0 : findTab;

    const tabs = [{
      label: 'In progress tasks',
      page: <TaskTableTab
        key="inprogress"
        baseTasksUrl={`${this.props.baseTasksUrl}?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=in_progress`}
        tabPaginationOptions={tabPaginationOptions}
        filterableTaskTypes={this.props.taskFilterDetails.in_progress}
        predefinedColumns={{ includeDaysWaiting: true,
          defaultSortIdx: 3 }} />
    }, {
      label: 'Completed tasks',
      page: <TaskTableTab
        key="completed"
        baseTasksUrl={`${this.props.baseTasksUrl}?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=completed`}
        tabPaginationOptions={tabPaginationOptions}
        filterableTaskTypes={this.props.taskFilterDetails.completed}
        description={COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION}
        predefinedColumns={{ includeCompletedDate: true,
          defaultSortIdx: 3 }} />
    }];

    return <TabWindow
      name="tasks-organization-queue"
      tabs={tabs}
      defaultPage={this.props.currentTab || getTabByIndex}
    />;
  }
}
NonCompTabsUnconnected.propTypes = {
  currentTab: PropTypes.node,
  dispatch: PropTypes.func,
  baseTasksUrl: PropTypes.string,
  taskFilterDetails: PropTypes.shape({
    in_progress: PropTypes.object,
    completed: PropTypes.object
  })
};

const NonCompTabs = connect(
  (state) => ({
    currentTab: state.currentTab,
    baseTasksUrl: state.baseTasksUrl,
    taskFilterDetails: state.taskFilterDetails
  })
)(NonCompTabsUnconnected);

export default NonCompTabs;
