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
import requiredValidator from '../util/validators/RequiredValidator';
import dateValidator from '../util/validators/DateValidator';

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

    if (requiredValidator('Please enter a certifying office.')(this.props.certifyingOffice)) {
      erroredFields.push('Name and location of certifying office:');
    }

    if (requiredValidator('Please enter a certifying username.')(this.props.certifyingUsername)) {
      erroredFields.push('Organizational elements certifying appeal:');
    }

    if (requiredValidator('Please enter an official name.')(this.props.certifyingOfficialName)) {
      erroredFields.push('Name of certifying official:');
    }

    if (requiredValidator('Please enter an official title.')(this.props.certifyingOfficialTitle)) {
      erroredFields.push('Title of certifying official:');
    }

    if (dateValidator('Please enter a date.')(this.props.certificationDate)) {
      erroredFields.push('Date:');
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

  isFieldErrored(fieldName, erroredFields) {
    if (erroredFields) {
      if (erroredFields.includes(fieldName)) {
        return true;
      }
    }
    return false;
  };

  render() {
    let {
      onSignAndCertifyFormChange,
      certifyingOffice,
      certifyingUsername,
      certifyingOfficialName,
      certifyingOfficialTitle,
      certificationDate,
      erroredFields,
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
            name="Name and location of certifying office:"
            value={certifyingOffice}
            errorMessage={(this.isFieldErrored("Name and location of certifying office:", erroredFields) ? "Please enter a certifying office." : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOffice')}/>
          <TextField
            name="Organizational elements certifying appeal:"
            value={certifyingUsername}
            errorMessage={(this.isFieldErrored("Organizational elements certifying appeal:", erroredFields) ? "Please enter an organizational element." : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingUsername')}/>
          <TextField
            name="Name of certifying official:"
            value={certifyingOfficialName}
            errorMessage={(this.isFieldErrored("Name of certifying official:", erroredFields) ? "Please enter a name of certifying official." : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialName')}/>
          <RadioField
            name="Title of certifying official:"
            options={certifyingOfficialTitleOptions}
            value={certifyingOfficialTitle}
            errorMessage={(this.isFieldErrored("Title of certifying official:", erroredFields) ? "Please enter a title of certifying official." : null)}
            required={true}
            onChange={onSignAndCertifyFormChange.bind(this, 'certifyingOfficialTitle')}/>
          <DateSelector
            name="Date:"
            value={certificationDate}
            errorMessage={(this.isFieldErrored("Date:", erroredFields) ? "Please enter a date." : null)}
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
    dispatch(certificationActions.changeErroredFields(erroredFields))
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
