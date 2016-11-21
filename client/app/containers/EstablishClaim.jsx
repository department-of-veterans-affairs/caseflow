import React, { PropTypes } from 'react';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import DropDown from '../components/DropDown';

const CONTESTED_CLAIMS = {
  Yes: true,
  No: false
};
const POA_CODES = {
  None: 0,
  VSO: 1,
  Private: 2
};
const CLAIM_LABEL_OPTIONS = [
  " ", 
  "172BVAG - BVA Grant", 
  "170PGAMC - AMC-Partial Grant", 
  "170RMDAMC - AMC-Remand"
];
const MODIFIER_OPTIONS = [
  "170", 
  "172"
];
const SEGMENTED_LANE_OPTIONS = [
  "Core (National)",
  "Spec Ops (National)"
];
const EMAIL_REGEX = /^[-a-z0-9~!$%^&*_=+}{\'?]+(\.[-a-z0-9~!$%^&*_=+}{\'?]+)*@([a-z0-9_][-a-z0-9_]*(\.[-a-z0-9_]+[a-z][a-z])|([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}))(:[0-9]{1,5})?$/i;

export default class EstablishClaim extends React.Component {
   constructor(props) {
     super(props);

     // Set initial state on page render
     this.state = {
       emailAddress: '',
       contestedClaims: null,
       remarks: ''
     }

     this.emailAddressValidationError = this.emailAddressValidationError.bind(this);
     this.handleEmailAddressChange = this.handleEmailAddressChange.bind(this);
     this.handleContestedClaimsChange = this.handleContestedClaimsChange.bind(this);
     this.handleRemarksChange = this.handleRemarksChange.bind(this);
   }

  emailAddressValidationError() {
    let { emailAddress } = this.state;

    if (!emailAddress.length) {
      return null;
    }

    if (!EMAIL_REGEX.test(emailAddress)) {
      return 'Not a valid email.'
    }
  }

  handleEmailAddressChange(e) {
    this.setState({
      emailAddress: e.target.value
    });
  }

  handleContestedClaimsChange(e) {
    this.setState({
      contestedClaims: CONTESTED_CLAIMS[e.target.value]
    });
  }

  handleRemarksChange(e) {
    this.setState({
      remarks: e.target.value
    });
  }

  render() {
    let { task } = this.props;
    let { user, appeal } = task;
    let { emailAddress, contestedClaims, remarks } = this.state;

    return (
      <div className="cf-app-segment">
         <h1>Dispatch Show WIP</h1>
         <p>Type: {task.type}</p>
         <p>user: {user.display_name}</p>
         <p>vacols_id: {appeal.vacols_id}</p>
         <form className="cf-form" noValidate>
           <TextField
             label="Benefit Type"
             name="BenefitType"
             value="C&P Live"
             readOnly={true}
           />
           <TextField
             label="Payee"
             name="Payee"
             value="00 - Veteran"
             readOnly={true}
           />
           <RadioField
             label="Are contested claims procedures applicable in this case?"
             name="ContestedClaims"
             value={emailAddress}
             onChange={this.handleContestedClaimsChange}
             options={Object.keys(CONTESTED_CLAIMS)}
           />
           {contestedClaims && <TextareaField
             name="Remarks"
             value={remarks}
             onChange={this.handleRemarksChange}
             counter={true}
           />}
           <DropDown
             label="Claim Label"
             name="ClaimLabel"
             options={CLAIM_LABEL_OPTIONS}
           />
           <DropDown
             label="Modifier"
             name="Modifier"
             options={MODIFIER_OPTIONS}
           />
           <DropDown
             label="Segmented Lane"
             name="SegmentedLane"
             options={SEGMENTED_LANE_OPTIONS}
           />
           <TextField
             label="Station"
             name="Station"
             value="499 - National Work Queue"
             readOnly={true}
           />
           <RadioField
             label="Are contested claims procedures applicable in this case?"
             name="ContestedClaims"
             value={Object.keys(POA_CODES)[0]}
             options={Object.keys(POA_CODES)}
           />
           <input type="submit"/>
         </form>
         <h3 style={{marginTop: '25px'}}>Current Values</h3>
         <p>Email Address: {emailAddress}</p>
         <p>Contested Claims: {`${contestedClaims}`}</p>
         <p>Remarks: {remarks}</p>
      </div>
    );
  }
}
