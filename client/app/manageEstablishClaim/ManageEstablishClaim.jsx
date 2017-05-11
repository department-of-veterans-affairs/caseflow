import React, { PropTypes } from 'react';
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
        footer: <b>Employee Total</b>
      },
      {
        header: 'Cases Completed',
        valueName: 'tasksCompletedCount',
        footer: <b>{quotaTotals.tasksCompletedCount}</b>,
        align: 'center'
      },
      {
        header: 'Cases Remaining',
        valueName: 'tasksLeftCount',
        footer: <b>{quotaTotals.tasksLeftCount}</b>,
        align: 'center'
      },
      {
        header: 'Cases Assigned',
        valueFunction: (userQuota) => (<AssignedTasks userQuota={userQuota} />),
        footer: <b>{quotaTotals.taskCount}</b>,
        align: 'center'
      },
      {
        valueFunction: (userQuota) => (<UserQuotaControls userQuota={userQuota} />)
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

        <EmployeeCount />

        <div className="cf-right-side">
          <a href="/dispatch/stats">
            <i className="fa fa-line-chart" aria-hidden="true"></i> View Dashboard
          </a>
        </div>

        <Table
          columns={this.getUserColumns()}
          rowObjects={userQuotas}
          rowClassNames={rowClassNames}
          summary="Appeals worked by user"
        />
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
