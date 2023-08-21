import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import TabWindow from '../../components/TabWindow';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import COPY from '../../../COPY';
import TaskTableTab from './TaskTableTab';
import useLocalFilterStorage from '../hooks/useLocalFilterStorage';

// comment for changes.

const NonCompTabsUnconnected = (props) => {
  const [localFilter, setFilter] = useLocalFilterStorage('nonCompFilter', []);

  // A callback function to send down to QueueTable to add filters to local storage when the get parameters are updated
  const onHistoryUpdate = (urlString) => {
    const url = new URL(urlString);
    const params = new URLSearchParams(url.search);
    const filterParams = params.getAll(`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`);

    setFilter(filterParams);
  };

  const isVhaBusinessLine = props.businessLineUrl === 'vha';

  const queryParams = new URLSearchParams(window.location.search);
  const currentTabName = queryParams.get(QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM) || 'in_progress';
  const defaultSortColumn = currentTabName === 'in_progress' ? 'daysWaitingColumn' : 'completedDateColumn';
  const getParamsFilter = queryParams.getAll(`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`);
  // Read from the url get params and the local filter. The get params should override the local filter.
  const filter = getParamsFilter.length > 0 ? getParamsFilter : localFilter;
  const tabPaginationOptions = {
    [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM),
    [QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM),
    [QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM) || 'desc',
    [QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM) ||
        defaultSortColumn,
    [`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`]: filter,
  };
  const tabArray = ['in_progress', 'completed'];
  // If additional tabs need to be added, include them in the array above
  // to be able to locate them by their index
  const findTab = tabArray.findIndex((tabName) => tabName === currentTabName);
  const getTabByIndex = findTab === -1 ? 0 : findTab;

  const tabs = [{
    label: 'In progress tasks',
    page: <TaskTableTab {...props}
      key="inprogress"
      baseTasksUrl={`${props.baseTasksUrl}?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=in_progress`}
      tabPaginationOptions={tabPaginationOptions}
      {...(isVhaBusinessLine ? { onHistoryUpdate } : {})}
      filterableTaskTypes={props.taskFilterDetails.in_progress}
      filterableTaskIssueTypes={props.taskFilterDetails.in_progress_issue_types}
      predefinedColumns={{ includeDaysWaiting: true,
        defaultSortIdx: 3 }} />
  }, {
    label: 'Completed tasks',
    page: <TaskTableTab {...props}
      key="completed"
      baseTasksUrl={`${props.baseTasksUrl}?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=completed`}
      tabPaginationOptions={tabPaginationOptions}
      {...(isVhaBusinessLine ? { onHistoryUpdate } : {})}
      filterableTaskTypes={props.taskFilterDetails.completed}
      filterableTaskIssueTypes={props.taskFilterDetails.completed_issue_types}
      description={COPY.QUEUE_PAGE_COMPLETE_LAST_SEVEN_DAYS_TASKS_DESCRIPTION}
      predefinedColumns={{ includeCompletedDate: true,
        defaultSortIdx: 3 }} />
  }];

  return (<TabWindow
    name="tasks-organization-queue"
    tabs={tabs}
    defaultPage={props.currentTab || getTabByIndex}
  />);
};

NonCompTabsUnconnected.propTypes = {
  currentTab: PropTypes.node,
  dispatch: PropTypes.func,
  baseTasksUrl: PropTypes.string,
  taskFilterDetails: PropTypes.shape({
    in_progress: PropTypes.object,
    in_progress_issue_types: PropTypes.object,
    completed: PropTypes.object,
    completed_issue_types: PropTypes.object,
  }),
  businessLineUrl: PropTypes.string,
};

const NonCompTabs = connect(
  (state) => ({
    currentTab: state.currentTab,
    baseTasksUrl: state.baseTasksUrl,
    taskFilterDetails: state.taskFilterDetails,
    businessLineUrl: state.businessLineUrl,
  })
)(NonCompTabsUnconnected);

export default NonCompTabs;
