import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import SearchBar from '../../components/SearchBar';
import { TaskTableUnconnected } from '../../queue/components/TaskTable';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import {
  claimantColumn,
  veteranParticipantIdColumn,
  veteranSsnColumn,
  decisionReviewTypeColumn,
  pendingIssueModificationColumn
} from './TaskTableColumns';
import {
  issueCountColumn,
  issueTypesColumn
} from '../../queue/components/TaskTableColumns';
import {
  buildDecisionReviewFilterInformation,
  extractEnabledTaskFilters,
  parseFilterOptions,
} from '../util/index';
import pluralize from 'pluralize';
import { snakeCase } from 'lodash';

class TaskTableTabUnconnected extends React.PureComponent {
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
      tabName: this.props.tabName
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
  };

  claimantColumnHelper = () => {
    const { tabName } = this.state;
    const claimantColumnObject = claimantColumn();
    const tabList = ['incomplete', 'pending'];

    if (tabList.includes(tabName)) {
      claimantColumnObject.valueFunction = (task) => {
        const claimType = pluralize(snakeCase(task.appeal.type));

        return <a href={`/${claimType}/${task.externalAppealId}/edit`}>{task.claimant.name}</a>;
      };
    }

    return claimantColumnObject;
  };

  getTableColumns = () => [
    this.claimantColumnHelper(),
    {
      ...decisionReviewTypeColumn(),
      ...buildDecisionReviewFilterInformation(
        this.props.filterableTaskTypes,
        this.enabledTaskFilters()
      )
    },
    this.props.featureToggles.decisionReviewQueueSsnColumn ?
      veteranSsnColumn() :
      veteranParticipantIdColumn(),
    issueCountColumn(),
    {
      ...issueTypesColumn(),
      filterOptions: parseFilterOptions(this.props.filterableTaskIssueTypes)
    },
    this.state.tabName === 'pending' ? pendingIssueModificationColumn() : null
  ].filter((column) => column !== null);

  enabledTaskFilters = () => extractEnabledTaskFilters(
    this.props.tabPaginationOptions[`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`]
  );

  render = () => {
    this.props.tabPaginationOptions[QUEUE_CONFIG.SEARCH_QUERY_REQUEST_PARAM] = this.state.searchValue;

    return <React.Fragment>
      <div className="search-and-description-container">
        <div className="cf-noncomp-queue-completed-task noncomp-tab-description">{this.props.description}</div>
        <div className="cf-search-ahead-parent cf-noncomp-search">
          <SearchBar
            id="searchBar"
            size="small"
            title={this.props.featureToggles.decisionReviewQueueSsnColumn ?
              'Search by Claimant Name, Veteran Participant ID, File Number or SSN' :
              ''}
            onChange={this.onChange}
            recordSearch={this.onSearch}
            placeholder="Type to search..."
            onClearSearch={this.onClearSearch}
            isSearchAhead
            value={this.state.searchText} />
        </div>
      </div>
      <div className="non-comp-queue-table-wrapper">
        <div className="section-hearings-list">
          <TaskTableUnconnected
            {...this.state.predefinedColumns}
            getKeyForRow={(row, object) => object.id}
            onHistoryUpdate={this.props.onHistoryUpdate}
            customColumns={this.getTableColumns()}
            tasks={[]}
            taskPagesApiEndpoint={this.props.baseTasksUrl}
            useTaskPagesApi
            tabPaginationOptions={this.props.tabPaginationOptions} />
        </div>
      </div>
    </React.Fragment>;
  };
}

TaskTableTabUnconnected.propTypes = {
  description: PropTypes.node,
  predefinedColumns: PropTypes.object,
  tasks: PropTypes.array,
  featureToggles: PropTypes.shape({
    decisionReviewQueueSsnColumn: PropTypes.bool,
  }),
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
  filterableTaskIssueTypes: PropTypes.object,
  onHistoryUpdate: PropTypes.func,
  tabName: PropTypes.string
};

const TaskTableTab = connect(
  (state) => ({
    featureToggles: state.nonComp.featureToggles
  }),
)(TaskTableTabUnconnected);

export default TaskTableTab;
