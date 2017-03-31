import React from 'react';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';

import Footer from './Footer';
import LoadingContainer from '../components/LoadingContainer';
import RadioField from '../components/RadioField';


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

const hearingChangeFoundQuestion = `What did the appellant request
in the document you found?`;
const hearingChangeFoundAnswers = [
  {
    displayText: 'They cancelled their hearing request.',
    value: Constants.hearingTypes.HEARING_CANCELLED
  },
  {
    displayText: 'They requested a board hearing via videoconference.',
    value: Constants.hearingTypes.VIDEO
  },
  {
    displayText: 'They requested a board hearing in Washington, DC.',
    value: Constants.hearingTypes.WASHINGTON_DC
  },
  {
    displayText: 'They requested a board hearing at a local VA office.',
    value: Constants.hearingTypes.TRAVEL_BOARD
  }
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


const formalForm9HearingQuestion = `Which box did the appellant select for the Optional
Board Hearing question above? Depending on the Form 9, this may be Question 8
or Question 10.`;
const formalForm9HearingAnswers = [{
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

const informalForm9HearingQuestion = `What optional board hearing preference,
if any, did the appellant request?`;
const informalForm9HearingAnswers = [{
  displayText: `Does not want an optional board hearing
  or did not mention a board hearing.`,
  value: Constants.hearingTypes.NO_HEARING_DESIRED
}, {
  displayText: 'Wants a board hearing and did not specify what type.',
  value: Constants.hearingTypes.HEARING_TYPE_NOT_SPECIFIED
}, {
  displayText: 'Wants a board hearing by videoconference.',
  value: Constants.hearingTypes.VIDEO
}, {
  displayText: 'Wants a board hearing in Washington, DC.',
  value: Constants.hearingTypes.WASHINGTON_DC
}, {
  displayText: 'Wants a board hearing at their regional office.',
  value: Constants.hearingTypes.TRAVEL_BOARD
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
  const shouldDisplayHearingChangeFound = hearingDocumentIsInVbms === 'true';
  const shouldDisplayTypeOfForm9Question = hearingDocumentIsInVbms === 'false';
  const form9IsFormal = form9Type === Constants.form9Types.FORMAL_FORM9;
  const form9IsInformal = form9Type === Constants.form9Types.INFORMAL_FORM9;
  const shouldDisplayFormalForm9Question = shouldDisplayTypeOfForm9Question &&
    form9IsFormal;
  const shouldDisplayInformalForm9Question = shouldDisplayTypeOfForm9Question &&
    form9IsInformal;

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

        {
          shouldDisplayHearingChangeFound &&
          <RadioField name={hearingChangeFoundQuestion}
            required={true}
            options={hearingChangeFoundAnswers}
            value={hearingType}
            onChange={onHearingTypeChange}/>
        }

        {
          shouldDisplayTypeOfForm9Question &&
          <RadioField name={typeOfForm9Question}
            required={true}
            options={typeOfForm9Answers}
            value={form9Type}
            onChange={onTypeOfForm9Change}/>
        }

        {
          shouldDisplayTypeOfForm9Question &&
          /* TODO: restore the accessibility stuff here.
            also, we should stop using rails pdf viewer */
          <LoadingContainer>
            <iframe
              className="cf-doc-embed cf-iframe-with-loading form9-viewer"
              title="Form8 PDF"
              src={`/certifications/${match.params.vacols_id}/form9_pdf`}>
            </iframe>
          </LoadingContainer>
        }

        {
          shouldDisplayFormalForm9Question &&
          <RadioField name={formalForm9HearingQuestion}
            options={formalForm9HearingAnswers}
            value={hearingType}
            required={true}
            onChange={onHearingTypeChange}/>
        }

        {
          shouldDisplayInformalForm9Question &&
          <RadioField name={informalForm9HearingQuestion}
            options={informalForm9HearingAnswers}
            value={hearingType}
            required={true}
            onChange={onHearingTypeChange}/>
        }
      </div>

      <Footer
        nextPageUrl={
          `/certifications/${match.params.vacols_id}/sign_and_certify`
        }/>
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
    onHearingDocumentChange: (event) => {
      dispatch({
        type: Constants.CHANGE_VBMS_HEARING_DOCUMENT,
        payload: {
          hearingDocumentIsInVbms: event.target.value
        }
      });
    },
    onTypeOfForm9Change: (event) => {
      dispatch({
        type: Constants.CHANGE_TYPE_OF_FORM9,
        payload: {
          form9Type: event.target.value
        }
      });
    },
    onHearingTypeChange: (event) => {
      dispatch({
        type: Constants.CHANGE_TYPE_OF_HEARING,
        payload: {
          hearingType: event.target.value
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
