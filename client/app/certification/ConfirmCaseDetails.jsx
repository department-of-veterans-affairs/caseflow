import React from 'react';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';
import { Link } from 'react-router-dom';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';

const UnconnectedConfirmCaseDetails = ({
    representativeType,
    onRepresentativeTypeChange,
    representativeName,
    onRepresentativeNameChange,
    match
}) => {

  return <div>
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Confirm Case Details</h2>

        <div>
          {`Review data from VBMS about the appellant's
            representative and make changes if necessary.`}
        </div>
        <RadioField name="Representative type"
          required={true}
          options={
          [
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
              displayText: "OTHER",
              value: Constants.representativeTypes.OTHER
            }
          ]
          }
          value={representativeType}
          onChange={onRepresentativeTypeChange}/>

          <TextField name="Representative name"
            value={representativeName}
            onChange={onRepresentativeNameChange}
            required={true}
          />
      </div>

      <div className="cf-app-segment">
        <a href="#confirm-cancel-certification"
          className="cf-action-openmodal cf-btn-link">
          Cancel Certification
        </a>
      </div>

      <Link to={`/certifications/${match.params.vacols_id}/confirm_hearing`}>
        <button type="button" className="cf-push-right">
          Continue
        </button>
      </Link>
    </div>;
};

/*
 * CONNECTED COMPONENT STUFF:
 *
 * the code below makes this into a "connected component"
 * which can read and update the redux store.
 * TODO: as a matter of convention, should we make the connecting
 * bits into their own file?
 * What naming convention should we use
 * for connected and unconnected components? So many
 * questions.
 *
 */

/*
 * These functions call `dispatch`, a Redux method
 * that causes the reducer in reducers/index.js
 * to return a new state object.
 */
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
    onRepresentativeTypeChange: (representativeType) => {
      dispatch({
        type: Constants.CHANGE_REPRESENTATIVE_TYPE,
        payload: {
          representativeType
        }
      });
    }
  };
};

/*
 * This function tells us which parts of the global
 * application state should be passed in as props to
 * the rendered component.
 */
const mapStateToProps = (state) => {
  return {
    representativeType: state.representativeType,
    representativeName: state.representativeName
  };
};


/*
 * Creates a component that's connected to the Redux store
 * using the state & dispatch map functions and the
 * ConfirmHearing function.
 */
const ConfirmCaseDetails = connect(
  mapStateToProps,
  mapDispatchToProps
)(UnconnectedConfirmCaseDetails);

export default ConfirmCaseDetails;
