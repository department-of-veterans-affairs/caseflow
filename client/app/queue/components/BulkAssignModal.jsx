import * as React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import { withRouter } from 'react-router-dom';
import ApiUtil from '../../util/ApiUtil';

import Button from '../../components/Button';
import Modal from '../../components/Modal';
import Dropdown from '../../components/Dropdown';

class BulkAssignModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      showModal: false,
      showErrors: false,
      users: [],
      modal: {
        assignedUser: undefined,
        regionalOffice: undefined,
        taskType: undefined,
        numberOfTasks: undefined
      }
    };
  }

  componentDidMount() {
    let fetchedUsers;

    ApiUtil.get(`/organizations/${this.props.match.params.organization}/users.json`).then((resp) => {
      fetchedUsers = resp.body.organization_users.data;

      this.setState({ users: fetchedUsers });
    });
  }

  handleModalToggle = () => {
    const modalStatus = this.state.showModal;

    this.setState({ showModal: !modalStatus });
  }

  onFieldChange = (value, field) => {
    let newState = this.state.modal;

    newState[field] = value;
    this.setState({ modal: newState });
    this.forceUpdate();
  }

  generateErrors = () => {
    const requiredFields = ['assignedUser', 'taskType', 'numberOfTasks'];
    const undefinedFields = _.keys(_.omitBy(this.state.modal, _.isString));
    const errorFields = [];

    undefinedFields.forEach((field) => {
      if (requiredFields.includes(field)) {
        errorFields.push(field);
      }
    });

    return errorFields;
  }

  bulkAssignTasks = () => {
    this.setState({ showErrors: true });

    if (this.generateErrors().length === 0) {
      // placeholder for posting data
      
      this.handleModalToggle()
    }
  }

  getDisplayTextOption = (options) => {
    const optionsWithDisplayText = [
      {
        value: null,
        displayText: ''
      }
    ];

    options.forEach((option) => {
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
    });

    return optionsWithDisplayText;
  }

  displayErrorMessage = (field) => {
    return this.state.showErrors && this.generateErrors().includes(field) ? 'Please select a value' : null;
  }

  generateUserOptions = () => {
    const users = this.state.users.map((user) => {
      return {
        value: user.attributes.css_id,
        displayText: `${user.attributes.css_id} ${user.attributes.full_name}`
      }
    });

    users.unshift({
      value: null,
      displayText: ''
    });

    return users;
  }

  generateRegionalOfficeOptions = () => {
    const options = _.uniq(this.props.tasks.map((task) => task.closestRegionalOffice));

    return this.getDisplayTextOption(options);
  }

  generateTaskTypeOptions = () => {
    let { tasks } = this.props;

    if (this.state.modal.regionalOffice) {
      tasks = _.filter(tasks, { closestRegionalOffice: this.state.modal.regionalOffice });
    }

    return this.getDisplayTextOption(_.uniq(tasks.map((task) => task.type)));
  }

  // generateNumberOfTaskOptions = () => {
  //   const allOptions = [5, 10, 20, 30, 40, 50];
  //   let taskOptions = [];

  //   for (let i = 0; i < allOptions.length; i++) {
  //     if (this.props.tasks.length > allOptions[i]) {
  //       taskOptions.push(allOptions[i]);
  //     } else {
  //       break;
  //     }
  //   }

  //   if (taskOptions.length === 0) {
  //     taskOptions.push(this.props.tasks.length);
  //   }
  // }

  render() {
    const bulkAssignButton = <Button onClick={this.handleModalToggle}>Assign Tasks</Button>;
    const confirmButton = <Button classNames={['usa-button-secondary']} onClick={this.bulkAssignTasks}>
      Assign
    </Button>;
    const cancelButton = <Button linkStyling onClick={this.handleModalToggle}>Cancel</Button>;

    console.log(this.props.match.params);

    return (
      <div>
        {this.state.showModal &&
          <Modal
            title="Assign Tasks"
            closeHandler={this.handleModalToggle}
            confirmButton={confirmButton}
            cancelButton={cancelButton} >
            <Dropdown
              name="Assign to"
              options={this.generateUserOptions()}
              value={this.state.modal.assignedUser}
              defaultText="Select"
              onChange={(value) => this.onFieldChange(value, 'assignedUser')}
              errorMessage={this.displayErrorMessage('assignedUser')}
              required
            />
            <Dropdown
              name="Regional office"
              options={this.generateRegionalOfficeOptions()}
              value={this.state.modal.regionalOffice}
              defaultText="Select"
              onChange={(value) => this.onFieldChange(value, 'regionalOffice')}
              errorMessages={this.displayErrorMessage('regionalOffice')}
            />
            <Dropdown
              name="Select task type"
              options={this.generateTaskTypeOptions()}
              value={this.state.modal.taskType}
              defaultText="Select"
              onChange={(value) => this.onFieldChange(value, 'taskType')}
              errorMessage={this.displayErrorMessage('taskType')}
              required
            />
            <Dropdown
              name="Select number of tasks to assign"
              options={this.getDisplayTextOption([5, 10, 20, 30, 40, 50])}
              value={this.state.modal.numberOfTasks}
              defaultText="Select"
              onChange={(value) => this.onFieldChange(value, 'numberOfTasks')}
              errorMessage={this.displayErrorMessage('numberOfTasks')}
              required
            />
          </Modal>
        }
        {bulkAssignButton}
      </div>
    );
  }
}

BulkAssignModal.propTypes = {
  tasks: PropTypes.array.isRequired
};

export default withRouter(BulkAssignModal);
