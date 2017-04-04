import React from 'react';
import TextField from '../components/TextField';
import DateSelector from '../components/DateSelector';
import RadioField from '../components/RadioField';
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
  componentWillMount() {
    this.props.updateProgressBar();
  }

  render(){
    let {
      certifyingOffice,
      onCertifyingOfficeChange,
      certifyingUsername,
      onCertifyingUsernameChange,
      certifyingOfficialName,
      onCertifyingOfficialNameChange,
      certifyingOfficialTitle,
      onCertifyingOfficialTitleChange,
      certificationDate,
      onCertificationDateChange
    } = this.props;

    return <div>
      <form noValidate id="end_product">
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Sign and Certify</h2>
          <p>Fill in information about yourself below to sign this certification.</p>

          <TextField
            name="Name and location of certifying office:"
            value={certifyingOffice}
            required={true}
            onChange={onCertifyingOfficeChange}/>
          <TextField
            name="Organizational elements certifying appeal:"
            value={certifyingUsername}
            required={true}
            onChange={onCertifyingUsernameChange}/>
          <TextField
            name="Name of certifying official:"
            value={certifyingOfficialName}
            required={true}
            onChange={onCertifyingOfficialNameChange}/>
          <RadioField
            name="Title of certifying official:"
            options={certifyingOfficialTitleOptions}
            value={certifyingOfficialTitle}
            required={true}
            onChange={onCertifyingOfficialTitleChange}/>
          <DateSelector
            name="Decision Date:"
            value={certificationDate}
            required={true}
            onChange={onCertificationDateChange}/>
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
  }
};

const mapDispatchToProps = (dispatch) => {
  return {
    updateProgressBar: () => {
      dispatch({
        type: Constants.UPDATE_PROGRESS_BAR,
        payload: {
          currentSection: Constants.progressBarSections.CONFIRMATION
        }
      });
    },
    onCertifyingOfficeChange: (certifyingOffice) => {
      dispatch({
        type: Constants.CHANGE_CERTIFYING_OFFICIAL,
        payload: {
          certifyingOffice
        }
      });
    },
    onCertifyingUsernameChange: (certifyingUsername) => {
      dispatch({
        type: Constants.CHANGE_CERTIFYING_USERNAME,
        payload: {
          certifyingUsername
        }
      });
    },
    onCertifyingOfficialNameChange: (certifyingOfficialName) => {
      dispatch({
        type: Constants.CHANGE_CERTIFYING_OFFICIAL_NAME,
        payload: {
          certifyingOfficialName
        }
      });
    },
    onCertifyingOfficialTitleChange: (certifyingOfficialTitle) => {
      dispatch({
        type: Constants.CHANGE_CERTIFYING_OFFICIAL_TITLE,
        payload: {
          certifyingOfficialTitle
        }
      });
    },
    onCertificationDateChange: (certificationDate) => {
      dispatch({
        type: Constants.CHANGE_CERTIFICATION_DATE,
        payload: {
          certificationDate
        }
      });
    }

  };
};

const mapStateToProps = (state) => {
  return {
    certifyingOffice: state.certifyingOffice,
    certifyingUsername: state.certifyingUsername,
    certifyingOfficialName: state.certifyingOfficialName,
    certifyingOfficialTitle: state.certifyingOfficialTitle,
    certificationDate: state.certificationDate
  };
};

const SignAndCertify = connect(
  mapStateToProps,
  mapDispatchToProps
)(UnconnectedSignAndCertify);

export default SignAndCertify;
