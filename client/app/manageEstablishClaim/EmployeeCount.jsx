import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import TextField from '../components/TextField';
import Button from '../components/Button';
import InlineForm from '../components/InlineForm';
import ApiUtil from '../util/ApiUtil';
import * as Constants from './constants/index';

class EmployeeCount extends React.Component {
  render() {
    let {
      employeeCount,
      handleEmployeeCountSave,
      handleEmployeeCountChange
    } = this.props;

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
            onClick={handleEmployeeCountSave(this.props)}
            disabled={!employeeCount}
          />
      </InlineForm>
    </div>;
  }
}

EmployeeCount.propTypes = {
  employeeCount: PropTypes.number.isRequired,
  handleEmployeeCountChange: PropTypes.func.isRequired,
  handleEmployeeCountSave: PropTypes.func.isRequired,
  handleAlert: PropTypes.func.isRequired
};

const mapStateToProps = (state) => {
  return { employeeCount: state.employeeCount };
};

const mapDispatchToProps = (dispatch) => ({
  handleEmployeeCountSave: (props) => () => {
    return ApiUtil.patch(`/dispatch/employee-count/${props.employeeCount}`).then(() => {
      window.location.reload();
    }, () => {
      props.handleAlert({
        type: 'error',
        title: 'Error',
        message: 'There was an error while updating the employee count. Please try again later'
      });
    });
  },
  handleEmployeeCountChange: (employeeCount) => {
    dispatch({
      type: Constants.CHANGE_EMPLOYEE_COUNT,
      payload: { employeeCount }
    });
  },
  handleAlert: (alert) => {
    dispatch({
      type: Constants.SET_ALERT,
      payload: { alert }
    });
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(EmployeeCount);
