import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import TabWindow from '../../components/TabWindow';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import COPY from '../../../COPY';
import TaskTableTab from './TaskTableTab';
import useLocalFilterStorage from '../hooks/useLocalFilterStorage';

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
  const defaultSortColumn = currentTabName === 'completed' ? 'completedDateColumn' : 'daysWaitingColumn';
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
  const tabArray = props.businessLineConfig.tabs;
  // If additional tabs need to be added, include them in the array above
  // to be able to locate them by their index
  const findTab = tabArray.findIndex((tabName) => tabName === currentTabName);
  const getTabByIndex = findTab === -1 ? 0 : findTab;

  // TODO: Add the correct description into copy.json here
  const incompleteDescription = 'Placeholder description ';

  const ALL_TABS = {
    incomplete: {
      label: 'Incomplete tasks',
      page: <TaskTableTab
        key="incomplete"
        baseTasksUrl={`${props.baseTasksUrl}?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=incomplete`}
        tabPaginationOptions={tabPaginationOptions}
        filterableTaskTypes={props.taskFilterDetails.incomplete}
        filterableTaskIssueTypes={props.taskFilterDetails.incomplete_issue_types}
        description={incompleteDescription}
        tabName="incomplete"
        predefinedColumns={{ includeDaysWaiting: true,
          defaultSortIdx: 3 }} />
    },
    in_progress: {
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
    },
    completed: {
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
    }
  };

  const tabs = Object.keys(ALL_TABS).
    filter((key) => props.businessLineConfig.tabs.includes(key)).
    map((key) => ALL_TABS[key]);

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
    incomplete: PropTypes.object,
    incomplete_issue_types: PropTypes.object,
    in_progress: PropTypes.object,
    in_progress_issue_types: PropTypes.object,
    completed: PropTypes.object,
    completed_issue_types: PropTypes.object,
  }),
  businessLineUrl: PropTypes.string,
  businessLineConfig: PropTypes.shape({ tabs: PropTypes.array })
};

const NonCompTabs = connect(
  (state) => ({
    currentTab: state.currentTab,
    baseTasksUrl: state.baseTasksUrl,
    taskFilterDetails: state.taskFilterDetails,
    businessLineUrl: state.businessLineUrl,
    businessLineConfig: state.businessLineConfig,
  })
)(NonCompTabsUnconnected);

export default NonCompTabs;
