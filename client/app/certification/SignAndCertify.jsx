import React from 'react';
import PropTypes from 'prop-types';
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
import { formatDateStr } from '../util/DateUtil';
import Header from './Header';
import CertificationProgressBar from './CertificationProgressBar';

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
  certificationDate: "Please enter today's date.",
  fieldLength: 'Please enter less than 40 characters in the field below.'
};

export class SignAndCertify extends React.Component {
  // TODO: updating state in UNSAFE_componentWillMount is
  // sometimes thought of as an anti-pattern.
  // is there a better way to do this?
  UNSAFE_componentWillMount() {
    this.props.updateProgressBar();
  }

  /* eslint class-methods-use-this: ["error", { "exceptMethods": ["componentDidMount"] }] */
  componentDidMount() {
    window.scrollTo(0, 0);
  }

  getValidationErrors() {

    const erroredFields = [];

    if (ValidatorsUtil.requiredValidator(this.props.certifyingOfficialName)) {
      erroredFields.push('certifyingOfficialName');
    } else if (ValidatorsUtil.lengthValidator(this.props.certifyingOfficialName)) {
      erroredFields.push('certifyingOfficialNameLength');
    }

    if (ValidatorsUtil.requiredValidator(this.props.certifyingOfficialTitle)) {
      erroredFields.push('certifyingOfficialTitle');
    }

    if (this.props.certifyingOfficialTitle === Constants.certifyingOfficialTitles.OTHER) {
      if (ValidatorsUtil.requiredValidator(this.props.certifyingOfficialTitleOther)) {
        erroredFields.push('certifyingOfficialTitleOther');
      } else if (ValidatorsUtil.lengthValidator(this.props.certifyingOfficialTitleOther)) {
        erroredFields.push('certifyingOfficialTitleOtherLength');
      }
    }

    return erroredFields;
  }

  onClickContinue() {
    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      this.props.showValidationErrors(erroredFields);

      return;
    }

    this.props.certificationUpdateStart({
      certifyingOfficialName: this.props.certifyingOfficialName,
      certifyingOfficialTitle: this.props.certifyingOfficialTitle,
      certifyingOfficialTitleOther: this.props.certifyingOfficialTitleOther,
      vacolsId: this.props.match.params.vacols_id
    });
  }

  isFieldErrored(fieldName) {
    return this.props.erroredFields && this.props.erroredFields.includes(fieldName);
  }

  certifyingOfficialNameError() {
    if (this.isFieldErrored('certifyingOfficialName')) {
      return ERRORS.certifyingOfficialName;
    } else if (this.isFieldErrored('certifyingOfficialNameLength')) {
      return ERRORS.fieldLength;
    }

    return null;
  }

  certifyingOfficialTitleOtherError() {
    if (this.isFieldErrored('certifyingOfficialTitleOther')) {
      return ERRORS.certifyingOfficialTitle;
    } else if (this.isFieldErrored('certifyingOfficialTitleOtherLength')) {
      return ERRORS.fieldLength;
    }

    return null;
  }

  componentDidUpdate () {
    if (this.props.scrollToError && this.props.erroredFields) {
      ValidatorsUtil.scrollToAndFocusFirstError();
      // This sets scrollToError to false so that users can edit other fields
      // without being redirected back to the first errored field.
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
      certifyingOfficialTitleOther,
      certificationDate,
      loading,
      updateSucceeded,
      serverError,
      match,
      certificationStatus
    } = this.props;

    if (!certificationStatus.includes('started')) {
      return <Redirect
        to={`/certifications/${match.params.vacols_id}/check_documents`} />;
    }

    if (updateSucceeded) {
      return <Redirect
        to={`/certifications/${match.params.vacols_id}/success`} />;
    }

    if (serverError) {
      return <Redirect
        to="/certifications/error" />;
    }

    const shouldDisplayCertifyingOfficialTitleOther =
      certifyingOfficialTitle === Constants.certifyingOfficialTitles.OTHER;

    return <div>
      <Header />
      <CertificationProgressBar />
      <form>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Sign and Certify</h2>
          <p>Fill in information about yourself below to sign this certification.</p>
          <div className="cf-help-divider"></div>
          <TextField
            name="Name and location of certifying office:"
            value={certifyingOffice}
            readOnly
          />
          <TextField
            name="Organizational elements certifying appeal:"
            value={certifyingUsername}
            readOnly
          />
          <TextField
            name="Name of certifying official:"
            value={certifyingOfficialName}
            errorMessage={this.certifyingOfficialNameError()}
            required
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialName')} />
          <RadioField
            name="Title of certifying official:"
            options={certifyingOfficialTitleOptions}
            value={certifyingOfficialTitle}
            errorMessage={(this.isFieldErrored('certifyingOfficialTitle') ? ERRORS.certifyingOfficialTitle : null)}
            required
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialTitle')} />
          {
            shouldDisplayCertifyingOfficialTitleOther &&
            <TextField
              name="Specify other title of certifying official:"
              value={certifyingOfficialTitleOther}
              errorMessage={this.certifyingOfficialTitleOtherError()}
              required
              onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialTitleOther')}
            />
          }
          <DateSelector
            name="Date:"
            value={formatDateStr(certificationDate)}
            readOnly
          />
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

  showValidationErrors: (erroredFields, scrollToError = true) => {
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
  certifyingOfficialTitleOther: state.certifyingOfficialTitleOther,
  certificationDate: state.certificationDate,
  erroredFields: state.erroredFields,
  scrollToError: state.scrollToError,
  loading: state.loading,
  updateSucceeded: state.updateSucceeded,
  serverError: state.serverError,
  certificationStatus: state.certificationStatus
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(SignAndCertify);

SignAndCertify.propTypes = {
  onSignAndCertifyFormChange: PropTypes.func,
  certifyingOffice: PropTypes.string,
  certifyingUsername: PropTypes.string,
  certifyingOfficialName: PropTypes.string,
  certifyingOfficialTitle: PropTypes.string,
  certifyingOfficialTitleOther: PropTypes.string,
  certificationDate: PropTypes.string,
  erroredFields: PropTypes.array,
  scrollToError: PropTypes.bool,
  match: PropTypes.object.isRequired,
  certificationStatus: PropTypes.string
};
