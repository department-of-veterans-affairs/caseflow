import React, { PropTypes } from 'react';
import TextField from '../components/TextField';
import DateSelector from '../components/DateSelector';
import RadioField from '../components/RadioField';
import Footer from './Footer';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';
import * as certificationActions from './actions/Certification';
import * as actions from './actions/SignAndCertify';
import { Redirect } from 'react-router-dom';
import ValidatorsUtil from '../util/ValidatorsUtil';

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

const CERTIFYING_OFFICE_ID = 'Name and location of certifying office:';
const CERTIFYING_USERNAME_ID = 'Organizational elements certifying appeal:';
const CERTIFYING_OFFICIAL_NAME_ID = 'Name of certifying official:';
const CERTIFYING_OFFICIAL_TITLE_ID = 'Title of certifying official:';
const CERTIFICATION_DATE_ID = 'Date:';
const CERTIFYING_OFFICE_ERROR = 'Please enter the certifying office.';
const CERTIFYING_USERNAME_ERROR = 'Please enter the organizational element.';
const CERTIFYING_OFFICIAL_NAME_ERROR = 'Please enter the name of the Certifying Official (usually your name).';
const CERTIFYING_OFFICIAL_TITLE_ERROR = 'Please enter the title of the Certifying Official ' +
    '(e.g. Decision Review Officer).';
const CERTIFICATION_DATE_ERROR = "Please enter today's date.";

class UnconnectedSignAndCertify extends React.Component {
  // TODO: updating state in ComponentWillMount is
  // sometimes thought of as an anti-pattern.
  // is there a better way to do this?
  componentWillMount() {
    this.props.updateProgressBar();
  }

  getValidationErrors() {

    const erroredFields = [];

    if (ValidatorsUtil.requiredValidator(this.props.certifyingOffice)) {
      erroredFields.push(CERTIFYING_OFFICE_ID);
    }

    if (ValidatorsUtil.requiredValidator(this.props.certifyingUsername)) {
      erroredFields.push(CERTIFYING_USERNAME_ID);
    }

    if (ValidatorsUtil.requiredValidator(this.props.certifyingOfficialName)) {
      erroredFields.push(CERTIFYING_OFFICIAL_NAME_ID);
    }

    if (ValidatorsUtil.requiredValidator(this.props.certifyingOfficialTitle)) {
      erroredFields.push(CERTIFYING_OFFICIAL_TITLE_ID);
    }

    if (ValidatorsUtil.dateValidator(this.props.certificationDate)) {
      erroredFields.push(CERTIFICATION_DATE_ID);
    }

    return erroredFields;
  }

  onClickContinue() {
    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      this.props.changeErroredFields(erroredFields);
      window.scrollBy(0, document.getElementById(erroredFields[0]).getBoundingClientRect().top - 30);

      return;
    }

    this.props.changeErroredFields(null);

    this.props.certificationUpdateStart({
      certifyingOffice: this.props.certifyingOffice,
      certifyingUsername: this.props.certifyingUsername,
      certifyingOfficialName: this.props.certifyingOfficialName,
      certifyingOfficialTitle: this.props.certifyingOfficialTitle,
      certificationDate: this.props.certificationDate,
      vacolsId: this.props.match.params.vacols_id
    });
  }

  isFieldErrored(fieldName) {
    return this.props.erroredFields && this.props.erroredFields.includes(fieldName);
  }

  render() {
    let {
      onSignAndCertifyFormChange,
      certifyingOffice,
      certifyingUsername,
      certifyingOfficialName,
      certifyingOfficialTitle,
      certificationDate,
      loading,
      updateSucceeded,
      updateFailed,
      match
    } = this.props;

    if (updateSucceeded) {
      return <Redirect
        to={`/certifications/${match.params.vacols_id}/success`}/>;
    }

    if (updateFailed) {
      // TODO: add real error handling and validated error states etc.
      return <div>500 500 error error</div>;
    }

    return <div>
      <form>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Sign and Certify</h2>
          <p>Fill in information about yourself below to sign this certification.</p>
          <TextField
            name={CERTIFYING_OFFICE_ID}
            value={certifyingOffice}
            errorMessage={(this.isFieldErrored(CERTIFYING_OFFICE_ID) ? CERTIFYING_OFFICE_ERROR : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOffice')}/>
          <TextField
            name={CERTIFYING_USERNAME_ID}
            value={certifyingUsername}
            errorMessage={(this.isFieldErrored(CERTIFYING_USERNAME_ID) ? CERTIFYING_USERNAME_ERROR : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingUsername')}/>
          <TextField
            name={CERTIFYING_OFFICIAL_NAME_ID}
            value={certifyingOfficialName}
            errorMessage={(this.isFieldErrored(CERTIFYING_OFFICIAL_NAME_ID) ? CERTIFYING_OFFICIAL_NAME_ERROR : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialName')}/>
          <RadioField
            name={CERTIFYING_OFFICIAL_TITLE_ID}
            options={certifyingOfficialTitleOptions}
            value={certifyingOfficialTitle}
            errorMessage={(this.isFieldErrored(CERTIFYING_OFFICIAL_TITLE_ID) ? CERTIFYING_OFFICIAL_TITLE_ERROR : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialTitle')}/>
          <DateSelector
            name={CERTIFICATION_DATE_ID}
            value={certificationDate}
            errorMessage={(this.isFieldErrored(CERTIFICATION_DATE_ID) ? CERTIFICATION_DATE_ERROR : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certificationDate')}/>
        </div>
      </form>
    <Footer
      disableContinue={false}
      loading={loading}
      onClickContinue={this.onClickContinue.bind(this)}
    />
  </div>;
  }
}

const mapDispatchToProps = (dispatch) => ({
  updateProgressBar: () => {
    dispatch(actions.updateProgressBar());
  },

  changeErroredFields: (erroredFields) => {
    dispatch(certificationActions.changeErroredFields(erroredFields));
  },

  onSignAndCertifyFormChange: (fieldName, value) => {
    dispatch(actions.onSignAndCertifyFormChange(fieldName, value));
  },

  certificationUpdateStart: (props) => {
    dispatch(actions.certificationUpdateStart(props, dispatch));
  }
});

const mapStateToProps = (state) => ({
  certifyingOffice: state.certifyingOffice,
  certifyingUsername: state.certifyingUsername,
  certifyingOfficialName: state.certifyingOfficialName,
  certifyingOfficialTitle: state.certifyingOfficialTitle,
  certificationDate: state.certificationDate,
  erroredFields: state.erroredFields,
  loading: state.loading,
  updateSucceeded: state.updateSucceeded,
  updateFailed: state.updateFailed
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
  erroredFields: PropTypes.array,
  match: PropTypes.object.isRequired
};

export default SignAndCertify;
