import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import SearchBar from '../../components/SearchBar';
import TabWindow from '../../components/TabWindow';
import { TaskTableUnconnected } from '../../queue/components/TaskTable';
import {
  claimantColumn,
  veteranParticipantIdColumn,
  decisionReviewTypeColumn,
  caseDetialsColumn,
  tasksColumn } from './TaskTableColumns';
import COPY from '../../../COPY';

class NonCompTabsUnconnected extends React.PureComponent {
  render = () => {
    const tabs = [{
      label: 'In progress tasks',
      page: <TaskTableTab
        key="inprogress"
        predefinedColumns={{ includeDaysWaiting: true,
          defaultSortIdx: 3 }}
        tasks={this.props.inProgressTasks}
        businessLine={this.props.businessLine} />
    }, {
      label: 'Completed tasks',
      page: <TaskTableTab
        key="completed"
        description={COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION}
        predefinedColumns={{ includeCompletedDate: true,
          defaultSortIdx: 3 }}
        tasks={this.props.completedTasks}
        businessLine={this.props.businessLine} />
    }];

    return <TabWindow
      name="tasks-organization-queue"
      tabs={tabs}
      defaultPage={this.props.currentTab}
    />;
  }
}

NonCompTabsUnconnected.propTypes = {
  completedTasks: PropTypes.array,
  currentTab: PropTypes.node,
  dispatch: PropTypes.func,
  inProgressTasks: PropTypes.array,
  businessLine: PropTypes.string,
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
    let columns = [claimantColumn(), veteranParticipantIdColumn(),
            decisionReviewTypeColumn(this.state.allTasks)];

    if (this.props.businessLine == "VHA CAMO") {
      columns = [caseDetialsColumn(), tasksColumn(), decisionReviewTypeColumn(this.state.allTasks)];
    }

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
          customColumns={columns}
          includeIssueCount
          tasks={this.state.shownTasks}
        />
      </div>
    </React.Fragment>;
  }
}

TaskTableTab.propTypes = {
  description: PropTypes.node,
  predefinedColumns: PropTypes.object,
  tasks: PropTypes.array,
  businessLine: PropTypes.string,
};

const NonCompTabs = connect(
  (state) => ({
    inProgressTasks: state.inProgressTasks,
    completedTasks: state.completedTasks,
    currentTab: state.currentTab
  })
)(NonCompTabsUnconnected);

export default NonCompTabs;
