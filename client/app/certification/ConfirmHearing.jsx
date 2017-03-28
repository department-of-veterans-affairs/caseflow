import React from 'react';
import { Link } from 'react-router-dom';
import LoadingContainer from '../components/LoadingContainer';
import RadioField from '../components/RadioField';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';




// TODO: how should we organize content?
// one school of thought is to put content
// in its own separate file.
// another is to make your react components
// small and self-contained enough that
// putting content with them doesn't
// cause file length bloat.

const hearingCheckText = `Check the appellant's eFolder for a hearing
cancellation or request added after 09/01/2017, the date the Form 9
(or statement in lieu of Form 9) was uploaded.`;

const hearingChangeQuestion = `Was a hearing cancellation or request added after
09/01/2017?`;
// TODO: make into constant?
const hearingChangeAnswers = [
  { displayText: 'Yes',
    value: 'true' },
  { displayText: 'No',
    value: 'false' }
];

const typeOfForm9Question = `Caseflow found the document below,
labeled as a Form 9, from the appellant's eFolder. What type of
substantive appeal is it?`;
const typeOfForm9Answers = [
  { displayText: 'Form 9',
    value: Constants.form9Types.FORMAL_FORM9 },
  { displayText: 'Statement in lieu of Form 9',
    value: Constants.form9Types.INFORMAL_FORM9 }
];


const typeOfHearingQuestion = `Which box did the appellant select for the Optional
Board Hearing question above? Depending on the Form 9, this may be Question 8
or Question 10.`;
const typeOfHearingAnswers = [{
  displayText: 'A. I do not want an optional board hearing',
  value: Constants.hearingTypes.NO_HEARING_DESIRED
}, {
  displayText: 'B. I want a hearing by videoconference at a local VA office.',
  value: Constants.hearingTypes.VIDEO
}, {
  displayText: 'C. I want a hearing in Washington, DC.',
  value: Constants.hearingTypes.WASHINGTON_DC
}, {
  displayText: 'D. I want a hearing at a local VA office.',
  value: Constants.hearingTypes.TRAVEL_BOARD
}, {
  displayText: 'No box selected.',
  value: Constants.hearingTypes.HEARING_TYPE_NOT_SPECIFIED
}];

/*
* Check the Veteran's hearing request in VBMS and update it in VACOLS.
*
* This was created to reduce the number of errors
* that show up in the activation process later on,
* thus paving the way for auto-activation.
*
* In its final form, it will show:
* The most recent form9 (where the VACOLS date matches the VBMS date)
* OR the most recent hearing change/cancellation/request document found
* in VBMS, if we can detect that based on the subject field in VBMS.
*
 */
// TODO: refactor to use shared components where helpful
const UnconnectedConfirmHearing = ({
    hearingDocumentIsInVbms,
    onHearingDocumentChange,
    form9Type,
    onTypeOfForm9Change,
    hearingType,
    onHearingTypeChange,
    match
}) => {
  return <div>
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Confirm Hearing</h2>

        <div>
          {hearingCheckText}
        </div>

        {/*
          TODO: would we be better served by
          making our connected components smaller?
          we could make e.g.
          HearingChangeRadioField,
          TypeOfForm9RadioField,
          HearingTypeChangeRadioField

          which would be a connected component with
          direct access to the Redux store.
        */}
        <RadioField name={hearingChangeQuestion}
          required={true}
          options={hearingChangeAnswers}
          value={hearingDocumentIsInVbms}
          onChange={onHearingDocumentChange}/>

        <RadioField name={typeOfForm9Question}
          required={true}
          options={typeOfForm9Answers}
          value={form9Type}
          onChange={onTypeOfForm9Change}/>

        {/* TODO: restore the accessibility stuff here.
          also, we should stop using rails pdf viewer */}
        <LoadingContainer>
          <iframe
            className="cf-doc-embed cf-iframe-with-loading"
            title="Form8 PDF"
            src={`/certifications/${match.params.vacols_id}/form9_pdf`}>
          </iframe>
        </LoadingContainer>

        <RadioField name={typeOfHearingQuestion}
          options={typeOfHearingAnswers}
          value={hearingType}
          required={true}
          onChange={onHearingTypeChange}/>
      </div>

      <div className="cf-app-segment">
        <a href="#confirm-cancel-certification"
          className="cf-action-openmodal cf-btn-link">
          Cancel Certification
        </a>
      </div>

      <Link to={`/certifications/${match.params.vacols_id}/sign_and_certify`}>
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
    onHearingDocumentChange: (hearingDocumentIsInVbms) => {
      dispatch({
        type: Constants.CHANGE_VBMS_HEARING_DOCUMENT,
        payload: {
          hearingDocumentIsInVbms
        }
      });
    },
    onTypeOfForm9Change: (form9Type) => {
      dispatch({
        type: Constants.CHANGE_TYPE_OF_FORM9,
        payload: {
          form9Type
        }
      });
    },
    onHearingTypeChange: (hearingType) => {
      dispatch({
        type: Constants.CHANGE_TYPE_OF_HEARING,
        payload: {
          hearingType
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
    hearingDocumentIsInVbms: state.hearingDocumentIsInVbms,
    form9Type: state.form9Type,
    hearingType: state.hearingType
  };
};


/*
 * Creates a component that's connected to the Redux store
 * using the state & dispatch map functions and the
 * ConfirmHearing function.
 */
const ConfirmHearing = connect(
  mapStateToProps,
  mapDispatchToProps
)(UnconnectedConfirmHearing);

export default ConfirmHearing;
