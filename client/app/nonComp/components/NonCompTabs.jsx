import React, { useMemo, useState } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import TabWindow from '../../components/TabWindow';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import COPY from '../../../COPY';
import TaskTableTab from './TaskTableTab';
import useLocalFilterStorage from '../hooks/useLocalFilterStorage';
import { cloneDeep, mapValues, sumBy } from 'lodash';
import { sprintf } from 'sprintf-js';
import { formatDateStr } from '../../util/DateUtil';
import moment from 'moment';

const NonCompTabsUnconnected = (props) => {
  const [localFilter, setFilter] = useLocalFilterStorage('nonCompFilter', []);
  const [tempDateFilter, setTempDateFilter] = useState('');
  const isVhaBusinessLine = props.businessLineUrl === 'vha';
  const queryParams = new URLSearchParams(window.location.search);
  const currentTabName = queryParams.get(QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM) || 'in_progress';
  const defaultSortColumn = currentTabName === 'completed' ? 'completedDateColumn' : 'daysWaitingColumn';
  const getParamsFilter = queryParams.getAll(`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`);
  // Read from the url get params and the local filter. The get params should override the local filter.
  let filter = getParamsFilter.length > 0 ? getParamsFilter : localFilter;

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

  // A callback function to send down to QueueTable to add filters to local storage when the get parameters are updated
  const onHistoryUpdate = (urlString) => {
    const url = new URL(urlString);
    const params = new URLSearchParams(url.search);
    const filterParams = params.getAll(`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`);

    // Completed date filter preservation is different since the column is not shared between tabs
    const completedDateFilter = filterParams.find((value) => value.includes('col=completedDateColumn'));
    const tabFromParams = params.get(QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM);

    if (completedDateFilter) {
      setTempDateFilter(completedDateFilter);
    } else if (!completedDateFilter && tabFromParams === 'completed') {
      // Since it is still in the completed tab without a filter, assume it was cleared
      setTempDateFilter('cleared');
    }

    setFilter(filterParams);
  };

  // Derive the different tab task counts from the task filters.
  const taskCounts = useMemo(() => (
    mapValues(props.taskFilterDetails, (obj) => sumBy(Object.values(obj)))
  ), [props.taskFilterDetails]);

  const buildCompletedTabDescriptionFromFilter = (filters) => {
    const completedDateFilter = filters.find((value) => value.includes('col=completedDateColumn'));

    if (!isVhaBusinessLine) {
      return COPY.QUEUE_PAGE_COMPLETE_LAST_SEVEN_DAYS_TASKS_DESCRIPTION;
    } else if (completedDateFilter) {
      const match = completedDateFilter.match(/val=([^&]*)/);

      if (match) {
        const dateFilter = match[1];
        const [mode, startDate = null, endDate = null] = dateFilter.split(',');

        const formattedStartDate = startDate ? formatDateStr(startDate) : '';

        const formattedEndDate = endDate ? formatDateStr(endDate) : '';

        // Object that defines how to build the string based on the mode
        const completedDateFilterModeHandlers = {
          before: `Before ${formattedStartDate}`,
          after: `After ${formattedStartDate}`,
          on: `On ${formattedStartDate}`,
          between: `Between ${formattedStartDate} and ${formattedEndDate}`,
          last7: 'Last 7 Days',
          last30: 'Last 30 Days',
          last365: 'Last 365 Days'
        };

        return sprintf(COPY.VHA_QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION_WITH_FILTER,
          completedDateFilterModeHandlers[mode]);
      }

    }

    return COPY.VHA_QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION;

  };

  // The VHA completed tasks tab should have an automatic prefilter of 7 days applied to it
  // A completed date filter in the get parameters should override this.
  const completedTabPaginationOptions = cloneDeep(tabPaginationOptions);

  // TODO: See if this can be condensed by always setting tempDateFilter with a default 7 days
  // And setting it to empty string when it's cleared and always replacing the date filter that is there
  if (isVhaBusinessLine) {
    if (tempDateFilter) {
      if (tempDateFilter === 'cleared') {
        // Filter was cleared so don't set a filter now
      } else {
        // It's an existing filter so add it to the filters like normally
        completedTabPaginationOptions['filter[]'].push(tempDateFilter);
      }
    } else {
      const containsCompletedDateFilter = completedTabPaginationOptions['filter[]'].
        some((item) => item.includes('col=completedDateColumn'));

      if (!containsCompletedDateFilter) {
        const sevenDaysAgoString = moment().subtract(7, 'days').
          format('YYYY-MM-DD');

        completedTabPaginationOptions['filter[]'].push(`col=completedDateColumn&val=last7,${sevenDaysAgoString},`);
      }
    }

  }

  const ALL_TABS = {
    incomplete: {
      label: `Incomplete Tasks (${taskCounts.incomplete})`,
      page: <TaskTableTab
        key="incomplete"
        baseTasksUrl={`${props.baseTasksUrl}?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=incomplete`}
        tabPaginationOptions={tabPaginationOptions}
        {...(isVhaBusinessLine ? { onHistoryUpdate } : {})}
        filterableTaskTypes={props.taskFilterDetails.incomplete}
        filterableTaskIssueTypes={props.taskFilterDetails.incomplete_issue_types}
        description={COPY.VHA_INCOMPLETE_TAB_DESCRIPTION}
        tabName="incomplete"
        predefinedColumns={{ includeDaysWaiting: true }} />
    },
    pending: {
      label: `Pending Tasks (${taskCounts.pending})`,
      page: <TaskTableTab {...props}
        key="pending"
        baseTasksUrl={`${props.baseTasksUrl}?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=pending`}
        tabPaginationOptions={tabPaginationOptions}
        {...(isVhaBusinessLine ? { onHistoryUpdate } : {})}
        description={props.isBusinessLineAdmin ?
          COPY.VHA_PENDING_REQUESTS_TAB_ADMIN_DESCRIPTION :
          COPY.VHA_PENDING_REQUESTS_TAB_DESCRIPTION}
        tabName="pending"
        filterableTaskTypes={props.taskFilterDetails.pending}
        filterableTaskIssueTypes={props.taskFilterDetails.pending_issue_types}
        predefinedColumns={{ includeDaysWaiting: true }} />
    },
    in_progress: {
      label: `In Progress Tasks (${taskCounts.in_progress})`,
      page: <TaskTableTab {...props}
        key="inprogress"
        baseTasksUrl={`${props.baseTasksUrl}?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=in_progress`}
        tabPaginationOptions={tabPaginationOptions}
        {...(isVhaBusinessLine ? { onHistoryUpdate } : {})}
        filterableTaskTypes={props.taskFilterDetails.in_progress}
        filterableTaskIssueTypes={props.taskFilterDetails.in_progress_issue_types}
        predefinedColumns={{ includeDaysWaiting: true }} />
    },
    completed: {
      label: 'Completed Tasks',
      page: <TaskTableTab {...props}
        key="completed"
        baseTasksUrl={`${props.baseTasksUrl}?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=completed`}
        tabPaginationOptions={completedTabPaginationOptions}
        {...(isVhaBusinessLine ? { onHistoryUpdate } : {})}
        filterableTaskTypes={props.taskFilterDetails.completed}
        filterableTaskIssueTypes={props.taskFilterDetails.completed_issue_types}
        description={buildCompletedTabDescriptionFromFilter(filter)}
        tabName="completed" />
    }
  };

  const tabs = Object.keys(ALL_TABS).
    filter((key) => props.businessLineConfig.tabs.includes(key)).
    map((key) => ALL_TABS[key]);

  const resetPageNumberOnTabChange = (value) => {
    // If the user has selected a new tab then we should reset the pagination page to 0
    // This is to prevent situations where Viewing 31-45 of 1 total gets displayed and blocks user navigation
    if (value !== getTabByIndex) {
      tabPaginationOptions.page = 0;
    }
  };

  return (<TabWindow
    onChange={((value) => resetPageNumberOnTabChange(value))}
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
    pending: PropTypes.object,
    pending_issue_types: PropTypes.object,
    in_progress: PropTypes.object,
    in_progress_issue_types: PropTypes.object,
    completed: PropTypes.object,
    completed_issue_types: PropTypes.object,
  }),
  isBusinessLineAdmin: PropTypes.bool,
  businessLineUrl: PropTypes.string,
  businessLineConfig: PropTypes.shape({ tabs: PropTypes.array })
};

const NonCompTabs = connect(
  (state) => ({
    currentTab: state.nonComp.currentTab,
    baseTasksUrl: state.nonComp.baseTasksUrl,
    taskFilterDetails: state.nonComp.taskFilterDetails,
    isBusinessLineAdmin: state.nonComp.isBusinessLineAdmin,
    businessLineUrl: state.nonComp.businessLineUrl,
    businessLineConfig: state.nonComp.businessLineConfig,
  })
)(NonCompTabsUnconnected);

export default NonCompTabs;
