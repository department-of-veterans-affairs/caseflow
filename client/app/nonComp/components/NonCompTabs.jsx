import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import SearchBar from '../../components/SearchBar';
import TabWindow from '../../components/TabWindow';
import { TaskTableUnconnected } from '../../queue/components/TaskTable';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import {
  claimantColumn,
  veteranParticipantIdColumn,
  veteranSsnColumn,
  decisionReviewTypeColumn,
} from './TaskTableColumns';
import {
  buildDecisionReviewFilterInformation,
  extractEnabledTaskFilters
} from '../util/index';
import COPY from '../../../COPY';

class NonCompTabsUnconnected extends React.PureComponent {
  render = () => {
    const queryParams = new URLSearchParams(window.location.search);
    const currentTabName = queryParams.get(QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM);
    const tabPaginationOptions = {
      [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM),
      [QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM),
      [QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM),
      [QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM]: queryParams.get(QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM),
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

class TaskTableTab extends React.PureComponent {
  constructor(props) {
    super(props);
    let searchText = '';

    // Set the search text to the get parameters if it exists
    if (this.props.tabPaginationOptions[QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM]) {
      searchText = this.props.tabPaginationOptions[QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM];
    }

    this.state = {
      predefinedColumns: this.props.predefinedColumns,
      searchText,
      searchValue: searchText,
    };
  }

  onChange = (value) => {
    if (!value) {
      // Edge case to reset the value if the user completely backspaces all of the text in the search input
      this.setState({ searchText: '', searchValue: '' });
    }

    this.setState({ searchText: value });
  };

  // Use a different state variable for debouncing
  // Pass this new value to queue table so it will resend the search on props/state change.
  onSearch = (value) => this.setState({ searchValue: value });

  onClearSearch = () => {
    this.setState({ searchText: '', searchValue: '' });
  }

  enabledTaskFilters = () => extractEnabledTaskFilters(
    this.props.tabPaginationOptions[`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`]
  )

  render = () => {
    this.props.tabPaginationOptions[QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM] = this.state.searchValue;

    return <React.Fragment>
      {this.props.description && <div className="cf-noncomp-queue-completed-task">{this.props.description}</div>}
      <div className="cf-search-ahead-parent cf-push-right cf-noncomp-search">
        <SearchBar
          id="searchBar"
          size="small"
          title="Search by Claimant Name, Veteran Participant ID, File Number or SSN"
          onChange={this.onChange}
          recordSearch={this.onSearch}
          placeholder="Type to search..."
          onClearSearch={this.onClearSearch}
          isSearchAhead
          value={this.state.searchText}
        />
      </div>
      <div className="section-hearings-list">
        <TaskTableUnconnected
          {...this.state.predefinedColumns}
          getKeyForRow={(row, object) => object.id}
          customColumns={[
            claimantColumn(),
            veteranSsnColumn(),
            {
              ...decisionReviewTypeColumn(),
              ...buildDecisionReviewFilterInformation(
                this.props.filterableTaskTypes,
                this.enabledTaskFilters()
              )
            }
          ]}
          includeIssueCount
          tasks={[]}
          taskPagesApiEndpoint={this.props.baseTasksUrl}
          useTaskPagesApi
          tabPaginationOptions={this.props.tabPaginationOptions}
        />
      </div>
    </React.Fragment>;
  }
}
TaskTableTab.propTypes = {
  description: PropTypes.node,
  predefinedColumns: PropTypes.object,
  tasks: PropTypes.array,
  baseTasksUrl: PropTypes.string,
  tabPaginationOptions: PropTypes.shape({
    [QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM]: PropTypes.string,
    [QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM]: PropTypes.string,
    [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: PropTypes.string,
    [`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`]: PropTypes.arrayOf(PropTypes.string),
    [QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM]: PropTypes.string,
    onPageLoaded: PropTypes.func
  }),
  filterableTaskTypes: PropTypes.object,
};

const NonCompTabs = connect(
  (state) => ({
    currentTab: state.currentTab,
    baseTasksUrl: state.baseTasksUrl,
    taskFilterDetails: state.taskFilterDetails
  })
)(NonCompTabsUnconnected);

export default NonCompTabs;
