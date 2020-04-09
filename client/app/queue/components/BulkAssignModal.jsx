import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import _ from 'lodash';

import ApiUtil from '../../util/ApiUtil';
import QueueFlowModal from './QueueFlowModal';
import Dropdown from '../../components/Dropdown';
import { cityForRegionalOfficeCode } from '../utils';
import { bulkAssignTasks } from '../QueueActions';
import { setActiveOrganization } from '../uiReducer/uiActions';
import LoadingScreen from '../../components/LoadingScreen';
import { LOGO_COLORS } from '../../constants/AppConstants';
import COPY from '../../../COPY';
import WindowUtil from '../../util/WindowUtil';

const BULK_ASSIGN_ISSUE_COUNT = [5, 10, 20, 30, 40, 50];

class BulkAssignModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      users: [],
      // Expect each row in taskCountForTypeAndRegionalOffice to have the following shape:
      // { count: 12, type: "NoShowHearingTask", regional_office: "RO31" }
      taskCountForTypeAndRegionalOffice: [],
      loadingComponent: null,
      modal: {
        assignedUser: null,
        regionalOffice: null,
        taskType: null,
        numberOfTasks: null
      }
    };
  }

  componentDidMount() {
    this.setState({ loadingComponent: <LoadingScreen spinnerColor={LOGO_COLORS.QUEUE.ACCENT} /> });

    ApiUtil.get(`/organizations/${this.organizationUrl()}/task_summary.json`).then((resp) => {
      this.setState({
        users: resp.body.members.data,
        taskCountForTypeAndRegionalOffice: JSON.parse(resp.body.task_counts),
        loadingComponent: null
      });
    }).
      catch(() => {
        this.setState({ loadingComponent: null });
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

    const {
      taskType,
      numberOfTasks,
      assignedUser,
      regionalOffice
    } = this.state.modal;

    const data = {
      bulk_task_assignment: {
        organization_url: this.organizationUrl(),
        regional_office: regionalOffice,
        assigned_to_id: assignedUser,
        task_type: taskType,
        task_count: numberOfTasks
      }
    };

    return ApiUtil.post('/bulk_task_assignments', { data }).then(() => {
      this.props.history.push(`/organizations/${this.organizationUrl()}`);
      WindowUtil.reloadWithPOST();
    }).
      catch(() => {
        // handle the error
      });
  }

  filterOptionsByRegionalOffice = (rows) => {
    if (!this.state.modal.regionalOffice) {
      return rows;
    }

    return rows.filter((row) => row.regional_office === this.state.modal.regionalOffice);
  }

  filterOptionsByTaskType = (rows) => {
    if (!this.state.modal.taskType) {
      return rows;
    }

    return rows.filter((row) => row.type === this.state.modal.taskType);
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

  prependBlankOption = (options) => ([{ value: null,
    displayText: '' }].concat(options));

  generateRegionalOfficeOptions = () => {
    const allRows = this.state.taskCountForTypeAndRegionalOffice;

    // Remove rows with null regional office codes.
    const validRows = allRows.filter((row) => row.regional_office);
    const filteredRows = this.filterOptionsByTaskType(validRows);

    const uniqueRows = _.uniq(filteredRows.map((row) => row.regional_office));
    const rowsSortedByCityName = _.sortBy(uniqueRows, [(roCode) => cityForRegionalOfficeCode(roCode)]);

    return this.prependBlankOption(
      rowsSortedByCityName.map((roCode) => ({
        value: roCode,
        displayText: cityForRegionalOfficeCode(roCode)
      }))
    );
  }

  generateTaskTypeOptions = () => {
    const allRows = this.state.taskCountForTypeAndRegionalOffice;
    const filteredRows = this.filterOptionsByRegionalOffice(allRows);

    return this.prependBlankOption(_.uniq(filteredRows.map((row) => row.type)).map((type) => ({
      value: type,
      displayText: type.replace(/([a-z])([A-Z])/g, '$1 $2')
    })
    ));
  }

  assignableTaskCount = () => {
    const allRows = this.state.taskCountForTypeAndRegionalOffice;
    const filteredRows = this.filterOptionsByTaskType(this.filterOptionsByRegionalOffice(allRows));

    return filteredRows.map((row) => row.count).reduce((first, second) => first + second, 0);
  }

  generateNumberOfTaskOptions = () => {
    const actualOptions = [];
    const issueCounts = BULK_ASSIGN_ISSUE_COUNT;

    const assignableTaskCount = this.assignableTaskCount();

    for (let i = 0; i < issueCounts.length; i++) {
      if (assignableTaskCount < issueCounts[i]) {
        actualOptions.push({
          value: assignableTaskCount,
          displayText: `${assignableTaskCount} (all available tasks)`
        });
        break;
      }
      if (assignableTaskCount > issueCounts[i]) {
        actualOptions.push({
          value: issueCounts[i],
          displayText: issueCounts[i]
        });
      }
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

  render = () => {
    if (this.state.loadingComponent) {
      return this.state.loadingComponent;
    }

    return <QueueFlowModal
      pathAfterSubmit={`/organizations/${this.organizationUrl()}`}
      button={COPY.BULK_ASSIGN_BUTTON_TEXT}
      onCancel={this.props.onCancel}
      submit={this.bulkAssignTasks}
      validateForm={this.validateForm}
      title={COPY.BULK_ASSIGN_MODAL_TITLE}>
      {this.generateDropdown('Assign to', 'assignedUser', this.generateUserOptions(), true)}
      {this.generateDropdown('Regional office', 'regionalOffice', this.generateRegionalOfficeOptions(), false)}
      {this.generateDropdown('Select task type', 'taskType', this.generateTaskTypeOptions(), true)}
      {this.generateDropdown('Select number of tasks to assign', 'numberOfTasks',
        this.generateNumberOfTaskOptions(), true)}
    </QueueFlowModal>;
  }
  ;
}

BulkAssignModal.propTypes = {
  bulkAssignTasks: PropTypes.func,
  highlightFormItems: PropTypes.bool,
  history: PropTypes.object,
  location: PropTypes.object,
  onCancel: PropTypes.func
};

const mapStateToProps = (state) => {
  const {
    highlightFormItems
  } = state.ui;

  return {
    highlightFormItems
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({ bulkAssignTasks,
    setActiveOrganization }, dispatch)
);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(BulkAssignModal));
