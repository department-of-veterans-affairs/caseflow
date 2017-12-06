import React from 'react';
import RadioField from '../../components/RadioField';
import Button from '../../components/Button';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setFormType } from '../redux/actions';
import { FORMS } from '../constants';
import _ from 'lodash';

class SelectForm extends React.PureComponent {
  render() {
    const radioOptions = _.map(FORMS, (name, key) => ({ value: key,
      displayText: name }));

    return <div>
      <h1>Welcome to Caseflow Intake!</h1>
      <p>Please select the form you are processing from the Centralized Mail Portal.</p>

      <RadioField
        name="form-select"
        label="Which form are you processing?"
        vertical
        strongLabel
        options={radioOptions}
        onChange={this.props.setFormType}
        value={this.props.formType}
      />
    </div>;
  }
}

export default connect(
  (state) => ({
    formType: state.formType
  }),
  (dispatch) => bindActionCreators({
    setFormType
  }, dispatch)
)(SelectForm);

class SelectFormButtonUnconnected extends React.PureComponent {
  handleClick = () => {
    this.props.history.push('/search');
  }

  render = () =>
    <Button
      name="continue-to-search"
      onClick={this.handleClick}
      legacyStyling={false}
      disabled={!this.props.formType}
    >
      Continue to search
    </Button>;
}

export const SelectFormButton = connect(
  ({ formType }) => ({ formType }),
)(SelectFormButtonUnconnected);
