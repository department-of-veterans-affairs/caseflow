import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import SearchBar from '../../components/SearchBar';
import TabWindow from '../../components/TabWindow';
import { getQueryParams } from 'app/util/QueryParamsUtil';
import { TaskTableUnconnected } from '../../queue/components/TaskTable';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import { claimantColumn, veteranParticipantIdColumn, decisionReviewTypeColumn } from './TaskTableColumns';
import COPY from '../../../COPY';

class NonCompTabsUnconnected extends React.PureComponent {
  render = () => {
    const queryParams = getQueryParams(window.location.search);
    const pageNum = queryParams['page'];
    const currentTabName = queryParams[QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM];
    const tabArray = ['in_progress', 'completed'];
    // If additional tabs need to be added, include them in the array above
    // to be able to locate them by their index
    let findTab = tabArray.findIndex((tabName) => tabName === currentTabName);
    const getTabByIndex = findTab === -1 ? 0 : findTab;

    const tabs = [{
      label: 'In progress tasks',
      page: <TaskTableTab
        key="inprogress"
        baseTasksUrl={`${this.props.baseTasksUrl}?tab=in_progress`}
        tabPaginationOptions={{ [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: pageNum }}
        predefinedColumns={{ includeDaysWaiting: true,
          defaultSortIdx: 3 }} />
    }, {
      label: 'Completed tasks',
      page: <TaskTableTab
        key="completed"
        baseTasksUrl={`${this.props.baseTasksUrl}?tab=completed`}
        tabPaginationOptions={{ [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: pageNum }}
        description={COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION}
        predefinedColumns={{ includeCompletedDate: true,
          defaultSortIdx: 3 }} />
    }];

    return <TabWindow
      name="tasks-organization-queue"
      tabs={tabs}
      defaultPage={getTabByIndex || this.props.currentTab}
    />;
  }
}
NonCompTabsUnconnected.propTypes = {
  completedTasks: PropTypes.array,
  currentTab: PropTypes.node,
  dispatch: PropTypes.func,
  baseTasksUrl: PropTypes.string,
};

class TaskTableTab extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      allTasks: this.props.tasks,
      predefinedColumns: this.props.predefinedColumns,
      shownTasks: this.props.tasks,
      searchText: '',
    };
  }
  onSearch = (searchText) => {
    const lowercaseSearchText = searchText.toLowerCase();
    const filteredTasks = this.state.allTasks.filter((task) => {
      return task.claimant.name.toLowerCase().includes(lowercaseSearchText) ||
        task.veteran_participant_id.includes(searchText);
    });

    this.setState({ shownTasks: filteredTasks,
      searchText });
  }
  onClearSearch = () => {
    this.setState({ shownTasks: this.state.allTasks,
      searchText: '' });
  }
  render = () => {
    return <React.Fragment>
      {this.props.description && <div className="cf-noncomp-queue-completed-task">{this.props.description}</div>}
      <div className="cf-search-ahead-parent cf-push-right cf-noncomp-search">
        <SearchBar
          id="searchBar"
          size="small"
          onChange={this.onSearch}
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
          customColumns={[claimantColumn(), veteranParticipantIdColumn(),
            decisionReviewTypeColumn(this.state.allTasks)]}
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
    [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: PropTypes.string,
    [QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM]: PropTypes.string,
    [QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM]: PropTypes.string,
    [`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`]: PropTypes.arrayOf(PropTypes.string),
    onPageLoaded: PropTypes.func
  })
};

const NonCompTabs = connect(
  (state) => ({
    completedTasks: state.completedTasks,
    currentTab: state.currentTab,
    baseTasksUrl: state.baseTasksUrl
  })
)(NonCompTabsUnconnected);

export default NonCompTabs;
