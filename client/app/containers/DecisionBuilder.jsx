import React, { PropTypes } from 'react';

import DropDown from '../components/DropDown';
import {
          FormField,
          handleFieldChange,
          getFormValues,
          validateFormAndSetErrors
       } from '../util/FormField';

const DEFINE_ISSUE_TYPE = 0;
const DEFINE_ISSUE_SUBTYPE = 1;
const ISSUE_TYPES = ['Bone', 'Joint', 'Arthritis'];

export default class DecisionBuilder extends React.Component {
  constructor(props) {
    super(props);
    
    this.handleFieldChange = handleFieldChange.bind(this);
    
    this.state = {
      step: DEFINE_ISSUE_TYPE,
      form: {
        issueType: new FormField(''),
        issueSubType: new FormField('')
      }
    };
  }

  showNextField = (event) => {
    this.setState({
      step: this.state.step + 1
    })
  }

  render() {
    return <div className="cf-app-segment cf-app-segment--alt">
        <h1>Specify Issue</h1>
        { this.state.step >= DEFINE_ISSUE_TYPE &&
          <DropDown
           label="Select the type of issue"
           name="issueType"
           options={ISSUE_TYPES}
           onChange={this.handleFieldChange('form', 'issueType', this.showNextField)}
           {...this.state.form.issueType}
          />
        }
        { this.state.step >= DEFINE_ISSUE_SUBTYPE &&
          <DropDown
           label="Select the sub-type of issue"
           name="issueSubType"
           options={ISSUE_TYPES}
           onChange={this.handleFieldChange('form', 'issueSubType', this.showNextField)}
           {...this.state.form.issueSubType}
          />
        }
      </div>;
  }
}