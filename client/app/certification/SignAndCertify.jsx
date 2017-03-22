import React from 'react';
import TextField from '../components/TextField';
import DateSelector from '../components/DateSelector';
import RadioField from '../components/RadioField';

// TODO: refactor to use shared components where helpful
const SignAndCertify = () => {
  return <div>
    <form noValidate id="end_product">
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Sign and Certify</h2>

        <p>Fill in information about yourself below to sign this certification.</p>
        <TextField
         label="Name and location of certifying office:"
         name="BenefitType"
         value="C&P Live"
         readOnly={true}
        />
        <TextField
         label="Organizational elements certifying appeal:"
         name="a"
         value="00 - Veteran"
         readOnly={true}
        />
        <TextField
         label="Name of certifying official:"
         name="Payee"
         value="00 - Veteran"
         readOnly={true}
        />
        <RadioField
         label="Name of certifying official:"
         name="Payee"
         options={["Decision Review Officer", "Rating Specialist", "Veterans Service Representative", "Claims Assistant", "Other"]}
        />
        <DateSelector
          label="Decision Date"
          name="Date:"
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
};

export default SignAndCertify;
