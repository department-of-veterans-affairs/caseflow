import React, { PropTypes } from 'react';
import TextField from '../../components/TextField';
import Button from '../../components/Button';

export default class TasksManagerEmployeeCount extends React.Component {
  render() {

    let {
      employeeCountForm,
      handleEmployeeCountUpdate,
      handleFieldChange
    } = this.props;

    return <div>
      <h3>Enter the number of people working today.</h3>
      <div className="usa-grid-half cf-push-row">
        <div className="cf-push-left">
          <TextField
            label="Number of people"
            name="employeeCount"
            readOnly={false}
            onChange={handleFieldChange('employeeCountForm', 'employeeCount')}
            placeholder={employeeCountForm.employeeCount.value}
            type="number"
            {...employeeCountForm.employeeCount}
          />
        </div>
        <div className="cf-push-left cf-button-aligned-with-textfield">
          <Button
            name="Update"
            onClick={handleEmployeeCountUpdate}
          />
        </div>
      </div>
    </div>
  }
}

TasksManagerEmployeeCount.propTypes = {
  employeeCountForm: PropTypes.object.isRequired,
  handleEmployeeCountUpdate: PropTypes.func.isRequired,
  handleFieldChange: PropTypes.func.isRequired
}