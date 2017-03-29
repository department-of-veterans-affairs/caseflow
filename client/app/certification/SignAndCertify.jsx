import React, { PropTypes } from 'react';
import TextField from '../components/TextField';
import DateSelector from '../components/DateSelector';
import RadioField from '../components/RadioField';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';

const certifyingOfficialTitalQuestion = 'Title of certifying official:';
const certifyingOfficialTitleAnswers = [{
  displayText: 'Decision Review Officer',
  value: Constants.certifyingOfficialTitles.DECISION_REVIEW_OFFICER
}, {
  displayText: 'Rating Specialist',
  value: Constants.certifyingOfficialTitles.RATING_SPECIALIST
}, {
  displayText: 'Veterans Service Representative',
    value: Constants.certifyingOfficialTitles.VETERANS_SERVICE_REPRESENTATIVE
}, {
  displayText: 'Claims Assistant',
  value: Constants.certifyingOfficialTitles.CLAIMS_ASSISTANT
}, {
  displayText: 'Other',
  value: Constants.certifyingOfficialTitles.OTHER
}];


const UnconnectedSignAndCertify = ({
    certifyingOfficialTitle,
    onCertifyingOfficialTitleChange
}) => {
  return <div>
    <form noValidate id="end_product">
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Sign and Certify</h2>
        <p>Fill in information about yourself below to sign this certification.</p>

        <RadioField
          name={certifyingOfficialTitalQuestion}
          options={certifyingOfficialTitleAnswers}
          value={certifyingOfficialTitle}
          required={true}
          onChange={onCertifyingOfficialTitleChange}/>
      </div>
    </form>

    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification"
        className="cf-action-openmodal cf-btn-link">
        Cancel certification
      </a>
      <button type="button" className="cf-push-right">
        Certify appeal
      </button>
    </div>
  </div>;
};

const mapDispatchToProps = (dispatch) => {
  return {
    onCertifyingOfficialTitleChange: (certifyingOfficialTitle) => {
      dispatch({
        type: Constants.CHANGE_CERTIFYING_OFFICIAL_TITLE,
        payload: {
          certifyingOfficialTitle
        }
      });
    }
  };
};

const mapStateToProps = (state) => {
  return {
    certifyingOfficialTitle: state.certifyingOfficialTitle
  };
};

const SignAndCertify = connect(
  mapStateToProps,
  mapDispatchToProps
)(UnconnectedSignAndCertify);

export default SignAndCertify;
