import React from 'react';
import { connect } from 'react-redux';

import SearchBar from '../../components/SearchBar';
import TabWindow from '../../components/TabWindow';
import { TaskTableUnconnected } from '../../queue/components/TaskTable';
import { claimantColumn, veteranParticipantIdColumn, decisionReviewTypeColumn } from './TaskTableColumns';

class NonCompTabsUnconnected extends React.PureComponent {
  render = () => {
    const tabs = [{
      label: 'In progress tasks',
      page: <TaskTableTab
        key="inprogress"
        predefinedColumns={{ includeDaysWaiting: true,
          defaultSortIdx: 3 }}
        tasks={this.props.inProgressTasks} />
    }, {
      label: 'Completed tasks',
      page: <TaskTableTab
        key="completed"
        predefinedColumns={{ includeCompletedDate: true,
          defaultSortIdx: 3 }}
        tasks={this.props.completedTasks} />
    }];

    return <TabWindow
      name="tasks-organization-queue"
      tabs={tabs}
      defaultPage={this.props.currentTab}
    />;
  }
}

class TaskTableTab extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      allTasks: this.props.tasks,
      predefinedColumns: this.props.predefinedColumns,
      shownTasks: this.props.tasks,
      searchText: ''
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
            decisionReviewTypeColumn(this.state.shownTasks)
          ]}
          includeIssueCount
          tasks={this.state.shownTasks}
        />
      </div>
    </React.Fragment>;
  }
}

const NonCompTabs = connect(
  (state) => ({
    inProgressTasks: state.inProgressTasks,
    completedTasks: state.completedTasks,
    currentTab: state.currentTab
  })
)(NonCompTabsUnconnected);

export default NonCompTabs;
