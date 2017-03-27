import React, { PropTypes } from 'react';
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import InlineField from '../../components/InlineField';

export default class TasksManagerEmployeeCount extends React.Component {
  render() {

    let {
      employeeCountForm,
      handleEmployeeCountUpdate,
      handleFieldChange
    } = this.props;

    return <div>
      <InlineField>
          <TextField
            label="Enter the number of people working today"
            name="employeeCount"
            readOnly={false}
            onChange={handleFieldChange('employeeCountForm', 'employeeCount')}
            placeholder={employeeCountForm.employeeCount.value}
            type="number"
            {...employeeCountForm.employeeCount}
          />
          <Button
            name="Update"
            onClick={handleEmployeeCountUpdate}
            disabled={!employeeCountForm.employeeCount.value}
          />
      </InlineField>
    </div>;
  }
}

TasksManagerEmployeeCount.propTypes = {
  employeeCountForm: PropTypes.object.isRequired,
  handleEmployeeCountUpdate: PropTypes.func.isRequired,
  handleFieldChange: PropTypes.func.isRequired
};
