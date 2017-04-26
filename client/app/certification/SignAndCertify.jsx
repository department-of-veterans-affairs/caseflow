import React, { PropTypes } from 'react';
import TextField from '../components/TextField';
import DateSelector from '../components/DateSelector';
import RadioField from '../components/RadioField';
import Footer from './Footer';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';
import * as certificationActions from './actions/Certification';

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

  getValidationErrors() {

    const erroredFields = [];

    if (!this.props.certifyingOffice) {
      erroredFields.push('certifyingOffice');
    }

    if (!this.props.certifyingUsername) {
      erroredFields.push('certifyingUsername');
    }

    if (!this.props.certifyingOfficialName) {
      erroredFields.push('certifyingOfficialName');
    }

    if (!this.props.certifyingOfficialTitle) {
      erroredFields.push('certifyingOfficialTitle');
    }

    // TODO: we should validate that it's a datetype
    if (!this.props.certificationDate) {
      erroredFields.push('certificationDate');
    }

    return erroredFields;
  }

  onClickContinue() {

    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      this.props.onContinueClickFailed();

      return;
    }

    // Sets continueClicked to false for the next page.
    this.props.onContinueClickSuccess();

    window.location = `/certifications/${this.props.match.params.vacols_id}/success`;
  }

  render() {
    let {
      onSignAndCertifyFormChange,
      certifyingOffice,
      certifyingUsername,
      certifyingOfficialName,
      certifyingOfficialTitle,
      certificationDate,
      continueClicked,
      certificationId
    } = this.props;

    // if the form input is not valid and the user has already tried to click continue,
    // disable the continue button until the validation errors are fixed.
    let disableContinue = false;

    if (this.getValidationErrors().length && continueClicked) {
      disableContinue = true;
    }

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
    <Footer
      disableContinue={disableContinue}
      onClickContinue={this.onClickContinue.bind(this)}
      certificationId={certificationId}
    />
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
  },
  onContinueClickFailed: () => dispatch(certificationActions.onContinueClickFailed()),
  onContinueClickSuccess: () => dispatch(certificationActions.onContinueClickSuccess())
});

const mapStateToProps = (state) => ({
  certifyingOffice: state.certifyingOffice,
  certifyingUsername: state.certifyingUsername,
  certifyingOfficialName: state.certifyingOfficialName,
  certifyingOfficialTitle: state.certifyingOfficialTitle,
  certificationDate: state.certificationDate,
  continueClicked: state.continueClicked,
  certificationId: state.certificationId
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
  match: PropTypes.object.isRequired,
  continueClicked: PropTypes.bool,
  certificationId: PropTypes.number
};

export default SignAndCertify;
