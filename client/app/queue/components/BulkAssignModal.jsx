import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import _ from 'lodash';

import ApiUtil from '../../util/ApiUtil';
import QueueFlowModal from './QueueFlowModal';
import Dropdown from '../../components/Dropdown';
import { regionalOfficeCity } from '../utils';
import { getUnassignedOrganizationalTasks } from '../selectors';
import { bulkAssignTasks } from '../QueueActions';
import {
  setActiveOrganization
} from '../uiReducer/uiActions';

const BULK_ASSIGN_ISSUE_COUNT = [5, 10, 20, 30, 40, 50];

class BulkAssignModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      users: [],
      modal: {
        assignedUser: null,
        regionalOffice: null,
        taskType: null,
        numberOfTasks: null
      }
    };
  }

  componentDidMount() {
    ApiUtil.get(`/organizations/${this.organizationUrl()}/task_summary.json`).then((resp) => {
      this.setState({ users: resp.body.members.data });
    }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  onFieldChange = (value, field) => {
    const newState = this.state.modal;

    newState[field] = value;
    this.setState({ modal: newState });
    this.forceUpdate();
  }

  bulkAssignTasks = () => {
    this.props.bulkAssignTasks(this.state.modal);

    const { taskType: task_type, numberOfTasks: task_count, assignedUser: assigned_to_id } = this.state.modal;
    const regionalOffice = _.uniq(this.props.tasks.filter((task) => {
      return regionalOfficeCity(task) === this.state.modal.regionalOffice;
    }))[0];
    const regionalOfficeKey = _.get(regionalOffice, 'closestRegionalOffice.key');

    const data = { bulk_task_assignment: {
      organization_url: this.organizationUrl(),
      regional_office: regionalOfficeKey,
      assigned_to_id,
      task_type,
      task_count }
    };

    return ApiUtil.post('/bulk_task_assignments', { data }).then(() => {
      this.props.history.push(`/organizations/${this.organizationUrl()}`);
      window.location.reload();
    }).
      catch(() => {
        // handle the error
      });
  }

  getDisplayTextOption = (options) => {
    const optionsWithDisplayText = [
      {
        value: null,
        displayText: ''
      }
    ];

    options.forEach((option) => {
      if (option !== null) {
        if (typeof option === 'object') {
          optionsWithDisplayText.push(option);
        } else {
          optionsWithDisplayText.push(
            {
              value: option,
              displayText: option
            }
          );
        }
      }
    });

    return optionsWithDisplayText;
  }

  filterTasks = (fieldName, fieldValue, tasks) => {
    let filteredTasks = tasks;

    filteredTasks = fieldValue ?
      _.filter(filteredTasks, { [fieldName]: fieldValue }) :
      filteredTasks;

    return filteredTasks;
  }

  filterTasksByRegionalOffice = (tasks) => {
    let filteredTasks = tasks;

    if (this.state.modal.regionalOffice) {
      filteredTasks = filteredTasks.filter((task) => {
        return regionalOfficeCity(task) === this.state.modal.regionalOffice;
      });
    }

    return filteredTasks;
  }

  filterTasksByTaskType = (tasks) => {
    let filteredTasks = tasks;

    if (this.state.modal.taskType) {
      filteredTasks = this.filterTasks('type', this.state.modal.taskType, filteredTasks);
    }

    return filteredTasks;
  }

  generateUserOptions = () => {
    const users = this.state.users.map((user) => {
      return {
        value: user.id,
        displayText: `${user.attributes.css_id} ${user.attributes.full_name}`
      };
    });

    return users;
  }

  // task.closestRegionalOffice.location_hash.city
  generateRegionalOfficeOptions = () => {
    const filteredTasks = this.filterTasksByTaskType(this.props.tasks);

    const options = _.uniq(filteredTasks.map((task) => {
      return regionalOfficeCity(task);
    })).filter(Boolean);

    return this.getDisplayTextOption(options);
  }

  // Field we care about is task.type
  generateTaskTypeOptions = () => {
    const filteredTasks = this.filterTasksByRegionalOffice(this.props.tasks);

    const taskOptions = _.uniq(filteredTasks.map((task) => task.type)).map((task) => {
      return {
        value: task,
        displayText: task.replace(/([a-z])([A-Z])/g, '$1 $2')
      };
    });

    return taskOptions;
  }

  generateNumberOfTaskOptions = () => {
    const actualOptions = [];
    const issueCounts = BULK_ASSIGN_ISSUE_COUNT;

    // TODO: Come back to dealing with this.
    // 
    // let filteredTasks = this.filterTasksByRegionalOffice(this.props.tasks);
    // filteredTasks = this.filterTasksByTaskType(filteredTasks);

    for (let i = 0; i < issueCounts.length; i++) {
      // if (filteredTasks && filteredTasks.length < issueCounts[i]) {
      //   actualOptions.push({
      //     value: filteredTasks.length,
      //     displayText: `${filteredTasks.length} (all available tasks)`
      //   });
      //   break;
      // }
      // if (filteredTasks.length > issueCounts[i]) {
        actualOptions.push({
          value: issueCounts[i],
          displayText: issueCounts[i]
        });
      // }
    }

    return actualOptions;
  }

  validateForm = () => {
    return this.state.modal.assignedUser !== null &&
      this.state.modal.taskType !== null &&
      this.state.modal.numberOfTasks !== null;
  }

  generateDropdown = (label, fieldName, options, isRequired) => <Dropdown
    name={label}
    options={options}
    value={this.state.modal[fieldName]}
    defaultText="Select"
    onChange={(value) => this.onFieldChange(value, fieldName)}
    errorMessage={this.props.highlightFormItems &&
      !this.state.modal[fieldName] &&
      isRequired ? 'Please select a value' : null}
    required={isRequired}
  />;

  organizationUrl = () => this.props.location.pathname.split('/')[2];

  render = () => <QueueFlowModal
    pathAfterSubmit={`/organizations/${this.organizationUrl()}`}
    button="Assign Tasks"
    submit={this.bulkAssignTasks}
    validateForm={this.validateForm}
    title="Bulk Assign Tasks">
    {this.generateDropdown('Assign to', 'assignedUser', this.generateUserOptions(), true)}
    {this.generateDropdown('Regional office', 'regionalOffice', this.generateRegionalOfficeOptions(), false)}
    {this.generateDropdown('Select task type', 'taskType', this.generateTaskTypeOptions(), true)}
    {this.generateDropdown('Select number of tasks to assign', 'numberOfTasks',
      this.generateNumberOfTaskOptions(), true)}
  </QueueFlowModal>;
}

const mapStateToProps = (state) => {
  const {
    highlightFormItems
  } = state.ui;

  return {
    highlightFormItems,
    tasks: getUnassignedOrganizationalTasks(state)
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({ bulkAssignTasks,
    setActiveOrganization }, dispatch)
);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(BulkAssignModal));
