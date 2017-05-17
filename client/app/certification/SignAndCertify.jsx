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

const ERRORS = {
  certifyingOffice: 'Please enter the certifying office.',
  certifyingUsername: 'Please enter the organizational element.',
  certifyingOfficialName: 'Please enter the name of the certifying official (usually your name).',
  certifyingOfficialTitle: 'Please enter the title of the certifying official.',
  certificationDate: "Please enter today's date."
};

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
      erroredFields.push('certifyingOffice');
    }

    if (ValidatorsUtil.requiredValidator(this.props.certifyingUsername)) {
      erroredFields.push('certifyingUsername');
    }

    if (ValidatorsUtil.requiredValidator(this.props.certifyingOfficialName)) {
      erroredFields.push('certifyingOfficialName');
    }

    if (ValidatorsUtil.requiredValidator(this.props.certifyingOfficialTitle)) {
      erroredFields.push('certifyingOfficialTitle');
    }

    if (ValidatorsUtil.dateValidator(this.props.certificationDate)) {
      erroredFields.push('certificationDate');
    }

    return erroredFields;
  }

  onClickContinue() {
    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      this.props.showValidationErrors(erroredFields, true);

      return;
    }

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

  componentDidUpdate () {
    if (this.props.scrollToError && this.props.erroredFields) {
      ValidatorsUtil.scrollToAndFocusFirstError();
      this.props.showValidationErrors(this.props.erroredFields, false);
    }
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
          <div className="cf-help-divider"></div>
          <TextField
            name={'Name and location of certifying office:'}
            value={certifyingOffice}
            errorMessage={(this.isFieldErrored('certifyingOffice') ? ERRORS.certifyingOffice : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOffice')}/>
          <TextField
            name={'Organizational elements certifying appeal:'}
            value={certifyingUsername}
            errorMessage={(this.isFieldErrored('certifyingUsername') ? ERRORS.certifyingUsername : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingUsername')}/>
          <TextField
            name={'Name of certifying official:'}
            value={certifyingOfficialName}
            errorMessage={(this.isFieldErrored('certifyingOfficialName') ? ERRORS.certifyingOfficialName : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialName')}/>
          <RadioField
            name="Title of certifying official:"
            options={certifyingOfficialTitleOptions}
            value={certifyingOfficialTitle}
            errorMessage={(this.isFieldErrored('certifyingOfficialTitle') ? ERRORS.certifyingOfficialTitle : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialTitle')}/>
          <DateSelector
            name={'Date:'}
            value={certificationDate}
            errorMessage={(this.isFieldErrored('certificationDate') ? ERRORS.certificationDate : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certificationDate')}/>
        </div>
      </form>
    <Footer
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

  showValidationErrors: (erroredFields, scrollToError) => {
    dispatch(certificationActions.showValidationErrors(erroredFields, scrollToError));
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
  scrollToError: state.scrollToError,
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
  scrollToError: PropTypes.bool,
  match: PropTypes.object.isRequired
};

export default SignAndCertify;
