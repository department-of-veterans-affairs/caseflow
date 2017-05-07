import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import TextField from '../components/TextField';
import Button from '../components/Button';
import InlineForm from '../components/InlineForm';
import ApiUtil from '../util/ApiUtil';
import * as Constants from './constants/index';

const EmployeeCount = ({ employeeCount, handleEmployeeCountSave, handleEmployeeCountChange }) => {
  return <div>
    <InlineForm>
        <TextField
          label="Enter the number of people working today"
          name="employeeCount"
          readOnly={false}
          onChange={handleEmployeeCountChange}
          value={employeeCount}
          type="number"
          {...employeeCount}
        />
        <Button
          name="Update"
          onClick={handleEmployeeCountSave(employeeCount)}
          disabled={!employeeCount}
        />
    </InlineForm>
  </div>;
};

EmployeeCount.propTypes = {
  employeeCount: PropTypes.number.isRequired,
  handleEmployeeCountChange: PropTypes.func.isRequired,
  handleEmployeeCountSave: PropTypes.func.isRequired
};

const mapStateToProps = (state) => ({ employeeCount: state.employeeCount });

const mapDispatchToProps = (dispatch) => ({
  handleEmployeeCountSave: (employeeCount) => () => {
    return ApiUtil.patch(`/dispatch/employee-count/${employeeCount}`).then((response) => {
      dispatch({
        type: Constants.SET_USER_QUOTAS_FROM_API,
        payload: { userQuotas: response.body }
      });
    }, () => {
      dispatch({
        type: Constants.SET_ALERT,
        payload: {
          alert: {
            type: 'error',
            title: 'Error',
            message: 'There was an error while updating the employee count. Please try again later.'
          }
        }
      });
    });
  },
  handleEmployeeCountChange: (employeeCount) => {
    dispatch({
      type: Constants.CHANGE_EMPLOYEE_COUNT,
      payload: { employeeCount }
    });
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(EmployeeCount);
