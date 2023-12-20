import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import SearchableDropdown from '../../../components/SearchableDropdown';
import TextareaField from '../../../components/TextareaField';

import { onChangeFormData } from '../../../components/common/actions';

class ScheduleHearingLaterWithAdminActionForm extends React.Component {

  getErrorMessages = (newValues) => {
    const values = {
      ...this.props.values,
      ...newValues
    };

    return {
      withAdminActionKlass: values.withAdminActionKlass ? false : 'Please enter an action',
      hasErrorMessages: !values.withAdminActionKlass
    };
  }

  getApiFormattedValues = (newValues) => {
    const values = {
      ...this.props.values,
      ...newValues
    };

    return {
      with_admin_action_klass: values.withAdminActionKlass,
      admin_action_instructions: values.adminActionInstructions
    };
  }

  onChange = (value) => {
    this.props.onChange({
      ...value,
      errorMessages: this.getErrorMessages(value),
      apiFormattedValues: this.getApiFormattedValues(value)
    });
  }

  render () {
    const { adminActionOptions, values, showErrorMessages } = this.props;

    return (
      <div>
        <SearchableDropdown
          errorMessage={showErrorMessages ? values.errorMessages.withAdminActionKlass : ''}
          label="Select Reason"
          strongLabel
          name="postponementReason"
          options={adminActionOptions}
          value={values.withAdminActionKlass}
          onChange={(val) => this.onChange({ withAdminActionKlass: val ? val.value : null })}
        />
        <TextareaField
          label="Instructions"
          strongLabel
          name="adminActionInstructions"
          value={values.adminActionInstructions}
          onChange={(val) => this.onChange({ adminActionInstructions: val })}
        />
      </div>
    );
  }
}

const mapStateToProps = (state) => ({
  values: state.components.forms.scheduleHearingLaterWithAdminAction || {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onChange: (value) => onChangeFormData('scheduleHearingLaterWithAdminAction', value)
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps)(ScheduleHearingLaterWithAdminActionForm);
