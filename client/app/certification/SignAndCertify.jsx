import React, { PropTypes } from 'react';
import TextField from '../components/TextField';
import DateSelector from '../components/DateSelector';
import RadioField from '../components/RadioField';

// TODO: refactor to use shared components where helpful
export default class SignAndCertify extends React.Component {
  render() {
    let {
      certifyingOffice,
      certifyingUsername,
      certifyingOfficialName,
      certifyingOfficialTitle,
      certificationDate
    } = this.props;

    return <div>
      <form noValidate id="end_product">
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Sign and Certify</h2>

          <p>Fill in information about yourself below to sign this certification.</p>
          <TextField
            label="Name and location of certifying office:"
            name="certifyingOffice"
            value={certifyingOffice}
            readOnly={true}
          />
          <TextField
            label="Organizational elements certifying appeal:"
            name="certifyingUsername"
            value={certifyingUsername}
            readOnly={true}
          />
          <TextField
            label="Name of certifying official:"
            name="certifyingOfficialName"
            value={certifyingOfficialName}
            readOnly={true}
          />
          <RadioField
            label="Title of certifying official:"
            name="certifyingOfficialTitle"
            value={certifyingOfficialTitle}
            options={[
              "Decision Review Officer",
              "Rating Specialist",
              "Veterans Service Representative",
              "Claims Assistant",
              "Other"
             ]}
          />
          <DateSelector
            label="Decision Date"
            name="certificationDate"
            value={certificationDate}
            readOnly={true}
          />
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
}

SignAndCertify.propTypes = {
  certifyingOffice: PropTypes.string.isRequired,
  certifyingUsername: PropTypes.string.isRequired,
  certifyingOfficialName: PropTypes.string.isRequired,
  certifyingOfficialTitle: PropTypes.string.isRequired,
  certificationDate: PropTypes.string.isRequired
};
