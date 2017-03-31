import React from 'react';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';
import { Link } from 'react-router-dom';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';

const representativeTypeOptions = [
  {
    displayText: "Attorney",
    value: Constants.representativeTypes.ATTORNEY
  },
  {
    displayText: "Agent",
    value: Constants.representativeTypes.AGENT
  },
  {
    displayText: "Organization",
    value: Constants.representativeTypes.ORGANIZATION
  },
  {
    displayText: "None",
    value: Constants.representativeTypes.NONE
  },
  {
    displayText: "Other",
    value: Constants.representativeTypes.OTHER
  }
];

/*
 * Confirm Case Details
 *
 * This page will display information from BGS
 * about the appellant's representation for the appeal
 * and confirm it.
 *
 * On the backend, we'll then update that information in VACOLS
 * if necessary. This was created since power of attorney
 * information in VACOLS is very often out of date, which can
 * in case delays -- attorneys can't access the appeal information
 * if they're not noted as being the appellant's representative
 *
 */

const UnconnectedConfirmCaseDetails = ({
    representativeType,
    onRepresentativeTypeChange,
    representativeName,
    onRepresentativeNameChange,
    otherRepresentativeType,
    onOtherRepresentativeTypeChange,
    match
}) => {

  const shouldShowOtherTypeField =
    representativeType === Constants.representativeTypes.OTHER;

  return <div>
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Confirm Case Details</h2>

        <div>
          {`Review data from BGS about the appellant's
            representative and make changes if necessary.`}
        </div>

        <RadioField name="Representative type"
          options={representativeTypeOptions}
          value={representativeType}
          onChange={onRepresentativeTypeChange}
          required={true}/>

        {
          shouldShowOtherTypeField &&
          <TextField
            name="Specify other representative type"
            value={otherRepresentativeType}
            onChange={onOtherRepresentativeTypeChange}
            required={true}/>
        }

        <TextField name="Representative name"
          value={representativeName}
          onChange={onRepresentativeNameChange}
          required={true}/>

      </div>

      <div className="cf-app-segment">
        <a href="#confirm-cancel-certification"
          className="cf-action-openmodal cf-btn-link">
          Cancel Certification
        </a>

        <Link to={`/certifications/${match.params.vacols_id}/confirm_hearing`}>
          <button type="button" className="cf-push-right">
            Continue
          </button>
        </Link>

      </div>

  </div>;
};

const mapDispatchToProps = (dispatch) => {
  return {
    onRepresentativeNameChange: (event) => {
      dispatch({
        type: Constants.CHANGE_REPRESENTATIVE_NAME,
        payload: {
          representativeName: event.target.value
        }
      });
    },
    onRepresentativeTypeChange: (event) => {
      dispatch({
        type: Constants.CHANGE_REPRESENTATIVE_TYPE,
        payload: {
          representativeType: event.target.value
        }
      });
    },
    onOtherRepresentativeTypeChange: (event) => {
      dispatch({
        type: Constants.CHANGE_REPRESENTATIVE_TYPE,
        payload: {
          otherRepresentativeType: event.target.value
        }
      });
    }
  };
};

const mapStateToProps = (state) => {
  return {
    representativeType: state.representativeType,
    representativeName: state.representativeName
  };
};

const ConfirmCaseDetails = connect(
  mapStateToProps,
  mapDispatchToProps
)(UnconnectedConfirmCaseDetails);

export default ConfirmCaseDetails;
