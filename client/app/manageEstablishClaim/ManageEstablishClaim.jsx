import React, { PropTypes } from 'react';
import EmployeeCount from './EmployeeCount';
import Table from '../components/Table';
import Alert from '../components/Alert';
import * as Constants from './constants/index';
import { connect } from 'react-redux';

class ManageEstablishClaim extends React.Component {
  getUserColumns = () => {
    let {
      completedCountToday,
      toCompleteCount,
      userQuotas
    } = this.props;

    // We return an empty row if there are no users in the table. Otherwise
    // we use the footer to display the totals.
    let noUsers = userQuotas.length === 0;

    return [
      {
        header: 'Employee Name',
        valueName: 'user_name',
        footer: noUsers ? '' : <b>Employee Total</b>
      },
      {
        header: 'Cases Assigned',
        valueName: 'task_count',
        footer: noUsers ?
          '0' :
          <b>{toCompleteCount + completedCountToday}</b>
      },
      {
        header: 'Cases Completed',
        valueName: 'tasks_completed_count',
        footer: noUsers ? '0' : <b>{completedCountToday}</b>
      },
      {
        header: 'Cases Remaining',
        valueName: 'tasks_left_count',
        footer: toCompleteCount
      }
    ];
  }

  render() {
    let {
      completedCountToday,
      toCompleteCount,
      userQuotas,
      alert,
      handleAlertClear
    } = this.props;

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
            {completedCountToday} out
            of {(toCompleteCount + completedCountToday)} cases completed today
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
          summary="Appeals worked by user"
        />
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => {
  return { alert: state.alert };
};

const mapDispatchToProps = (dispatch) => ({
  handleAlertClear: () => dispatch({ type: Constants.CLEAR_ALERT })
});

ManageEstablishClaim.propTypes = {
  userQuotas: PropTypes.arrayOf(PropTypes.object).isRequired,
  completedCountToday: PropTypes.number.isRequired,
  employeeCount: PropTypes.number.isRequired,
  toCompleteCount: PropTypes.number.isRequired,
  alert: PropTypes.object,
  handleAlertClear: PropTypes.func.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(ManageEstablishClaim);
