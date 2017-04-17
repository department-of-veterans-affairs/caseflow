import React, { PropTypes } from 'react';
import TextField from '../components/TextField';
import DateSelector from '../components/DateSelector';
import RadioField from '../components/RadioField';
import Footer from './Footer';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';


const certifyingOfficialTitleOptions = [{
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

class UnconnectedSignAndCertify extends React.Component {
  // TODO: updating state in ComponentWillMount is
  // sometimes thought of as an anti-pattern.
  // is there a better way to do this?
  componentWillMount() {
    this.props.updateProgressBar();
  }

  render() {
    let {
      onSignAndCertifyFormChange,
      certifyingOffice,
      certifyingUsername,
      certifyingOfficialName,
      certifyingOfficialTitle,
      certificationDate,
      match
    } = this.props;

    return <div>
      <form>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Sign and Certify</h2>
          <p>Fill in information about yourself below to sign this certification.</p>
          <TextField
            name="Name and location of certifying office:"
            value={certifyingOffice}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOffice')}/>
          <TextField
            name="Organizational elements certifying appeal:"
            value={certifyingUsername}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingUsername')}/>
          <TextField
            name="Name of certifying official:"
            value={certifyingOfficialName}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialName')}/>
          <RadioField
            name="Title of certifying official:"
            options={certifyingOfficialTitleOptions}
            value={certifyingOfficialTitle}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialTitle')}/>
          <DateSelector
            name="Decision Date:"
            value={certificationDate}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certificationDate')}/>
        </div>
      </form>
    <Footer nextPageUrl={
      `/certifications/${match.params.vacols_id}/success`
    }/>
  </div>;
  }
}

const mapDispatchToProps = (dispatch) => ({
  updateProgressBar: () => {
    dispatch({
      type: Constants.UPDATE_PROGRESS_BAR,
      payload: {
        currentSection: Constants.progressBarSections.SIGN_AND_CERTIFY
      }
    });
  },
  onSignAndCertifyFormChange: (fieldName, value) => {
    dispatch({
      type: Constants.CHANGE_SIGN_AND_CERTIFY_FORM,
      payload: {
        [fieldName]: value
      }
    });
  }
});

const mapStateToProps = (state) => ({
  certifyingOffice: state.certifyingOffice,
  certifyingUsername: state.certifyingUsername,
  certifyingOfficialName: state.certifyingOfficialName,
  certifyingOfficialTitle: state.certifyingOfficialTitle,
  certificationDate: state.certificationDate
});

const SignAndCertify = connect(
  mapStateToProps,
  mapDispatchToProps
)(UnconnectedSignAndCertify);

SignAndCertify.propTypes = {
  onSignAndCertifyFormChange: PropTypes.func,
  certifyingOffice: PropTypes.string,
  certifyingUsername: PropTypes.string,
  certifyingOfficialName: PropTypes.string,
  certifyingOfficialTitle: PropTypes.string,
  certificationDate: PropTypes.string,
  match: PropTypes.object.isRequired
};

export default SignAndCertify;
