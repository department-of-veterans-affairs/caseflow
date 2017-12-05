import React from 'react';
import RadioField from '../../components/RadioField';
import Button from '../../components/Button';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setFormSelection } from '../redux/actions';
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
        onChange={this.props.setFormSelection}
        value={this.props.formSelection}
      />
    </div>;
  }
}

export default connect(
  (state) => ({
    formSelection: state.formSelection
  }),
  (dispatch) => bindActionCreators({
    setFormSelection
  }, dispatch)
)(SelectForm);

class SelectFormButton extends React.PureComponent {
  handleClick = () => {
    this.props.history.push('/search');
  }

  render = () =>
    <Button
      name="continue-to-search"
      onClick={this.handleClick}
      legacyStyling={false}
      disabled={!this.props.formSelection}
    >
      Continue to search
    </Button>;
}

const SelectFormButtonConnected = connect(
  ({ formSelection }) => ({ formSelection }),
)(SelectFormButton);

export class SelectFormButtons extends React.PureComponent {
  render = () =>
    <div>
      <SelectFormButtonConnected history={this.props.history} />
    </div>
}
