import React from 'react';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import Footer from './Footer';

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

      <Footer
        nextPageUrl={`/certifications/${match.params.vacols_id}/confirm_hearing`}
      />
  </div>;
};

const mapDispatchToProps = (dispatch) => {
  return {
    onRepresentativeNameChange: (representativeName) => {
      dispatch({
        type: Constants.CHANGE_REPRESENTATIVE_NAME,
        payload: {
          representativeName
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
    onOtherRepresentativeTypeChange: (otherRepresentativeType) => {
      dispatch({
        type: Constants.CHANGE_REPRESENTATIVE_TYPE,
        payload: {
          otherRepresentativeType
        }
      });
    }
  };
};

const mapStateToProps = (state) => {
  return {
    representativeType: state.representativeType,
    representativeName: state.representativeName,
    otherRepresentativeType: state.otherRepresentativeType
  };
};

const ConfirmCaseDetails = connect(
  mapStateToProps,
  mapDispatchToProps
)(UnconnectedConfirmCaseDetails);

export default ConfirmCaseDetails;
