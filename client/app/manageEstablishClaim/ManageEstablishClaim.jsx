import React from 'react';
import PropTypes from 'prop-types';

import EmployeeCount from './EmployeeCount';
import Table from '../components/Table';
import Alert from '../components/Alert';
import AssignedTasks from './AssignedTasks';
import UserQuotaControls from './UserQuotaControls';
import * as Constants from './constants/index';
import { getQuotaTotals } from './selectors';
import { connect } from 'react-redux';

class ManageEstablishClaim extends React.Component {
  getUserColumns = () => {
    let quotaTotals = this.props.quotaTotals;

    return [
      {
        header: 'Employee Name',
        valueName: 'userName',
        footer: <strong>Employee Total</strong>
      },
      {
        header: 'Cases Completed',
        valueName: 'tasksCompletedCount',
        footer: <strong>{quotaTotals.tasksCompletedCount}</strong>,
        align: 'center'
      },
      {
        header: 'Cases Remaining',
        valueName: 'tasksLeftCount',
        footer: <strong>{quotaTotals.tasksLeftCount}</strong>,
        align: 'center'
      },
      {
        header: 'Cases Assigned',
        valueFunction: (userQuota) => <AssignedTasks userQuota={userQuota} />,
        footer: <strong>{quotaTotals.taskCount}</strong>,
        align: 'center'
      },
      {
        valueFunction: (userQuota) => <UserQuotaControls userQuota={userQuota} />
      }
    ];
  }

  render() {
    let {
      userQuotas,
      quotaTotals,
      alert,
      handleAlertClear
    } = this.props;

    const rowClassNames = (userQuota) => {
      return userQuota.isAssigned ? '' : 'cf-gray';
    };

    return <div>
      {alert && <Alert
        type={alert.type}
        title={alert.title}
        message={alert.message}
        handleClear={handleAlertClear}
      />}

      <div className="cf-app-segment cf-app-segment--alt">
        <h1>ARC Work Assignments
          <span className="cf-associated-header">
            {quotaTotals.tasksCompletedCount} out of {quotaTotals.taskCount} cases completed today
          </span>
        </h1>

        <h2>Manage Work Assignments</h2>

        <EmployeeCount />

        <Table
          columns={this.getUserColumns()}
          rowObjects={userQuotas}
          rowClassNames={rowClassNames}
          summary="Appeals worked by user"
        />

        <h2>ARC Reports</h2>
        <p>
          <a href="/dispatch/canceled" target="_blank">
            View Canceled Tasks <i className="fa fa-external-link" aria-hidden="true"></i>
          </a>
        </p>
        <p>
          <a href="/dispatch/stats">
            View Dashboard <i className="fa fa-line-chart" aria-hidden="true"></i>
          </a>
        </p>

        <h2>BVA Reports</h2>
        <p>
          <a href="/dispatch/missing-decision" target="_blank">
            View Claims Missing Decisions in VBMS <i className="fa fa-external-link" aria-hidden="true"></i>
          </a>
        </p>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    userQuotas: state.userQuotas,
    quotaTotals: getQuotaTotals(state),
    alert: state.alert
  };
};

const mapDispatchToProps = (dispatch) => ({
  handleAlertClear: () => dispatch({ type: Constants.CLEAR_ALERT })
});

ManageEstablishClaim.propTypes = {
  userQuotas: PropTypes.arrayOf(PropTypes.object).isRequired,
  quotaTotals: PropTypes.object.isRequired,
  alert: PropTypes.object,
  handleAlertClear: PropTypes.func.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(ManageEstablishClaim);
