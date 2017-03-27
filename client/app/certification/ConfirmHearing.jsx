import React from 'react';
import { Link } from 'react-router-dom';
import LoadingContainer from '../components/LoadingContainer';
import RadioField from '../components/RadioField';
import { connect } from 'react-redux';

const hearingCheckText = `Check the appellant's eFolder for a hearing
cancellation or request added after 09/01/2017, the date the Form 9
(or statement in lieu of Form 9) was uploaded.`;

const hearingChangeQuestion = `Was a hearing cancellation or request added after
09/01/2017?`;
const hearingChangeAnswers = [
  { displayText: 'Yes', value: 'true' },
  { displayText: 'No', value: 'false' }
];

const typeOfForm9Question = `Caseflow found the document below, labeled as a Form 9,
from the appellant's eFolder. What type of substantive appeal is it?`;
const typeOfForm9Answers = [
  {displayText: 'Form 9', value: 'FORMAL'},
  {displayText: 'Statement in lieu of Form 9', value: 'INFORMAL'}
];

const typeOfHearingQuestion = `Which box did the appellant select for the Optional
Board Hearing question above? Depending on the Form 9, this may be Question 8
or Question 10.`;
const typeOfHearingAnswers = [{
  displayText: 'A. I do not want an optional board hearing',
  value: 'NO_HEARING_DESIRED'
},{
  displayText: 'B. I want a hearing by videoconference at a local VA office.',
  value: 'VIDEO'
},{
  displayText: 'C. I want a hearing in Washington, DC.',
  value: 'BVA'
},{
  displayText: 'D. I want a hearing at a local VA office.',
  value: 'TRAVEL_BOARD'
},{
  displayText: 'No box selected.',
  value: 'NO_HEARING_SELECTION'
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

const mapDispatchToProps = (dispatch) => {
  return {
    onHearingDocumentChange: (hearingDocumentIsInVbms) => {
      debugger;
      dispatch({
        type: 'CHANGE_VBMS_HEARING_DOCUMENT',
        hearingDocumentIsInVbms: hearingDocumentIsInVbms
      });
    },
    onTypeOfForm9Change: (form9Type) => {
      dispatch({
        type: 'CHANGE_TYPE_OF_FORM9',
        form9Type: form9Type
      });
    },
    onHearingTypeChange: (hearingType) => {
      dispatch({
        type: 'CHANGE_TYPE_OF_HEARING',
        hearingType: hearingType
      });
    }
  };
}

const mapStateToProps = (state) => {
  debugger;
  return {
    hearingDocumentIsInVbms: state.hearingDocumentIsInVbms,
    form9Type: state.form9Type,
    hearingType: state.hearingType
  };
};

// TODO: refactor to use shared components where helpful
const _ConfirmHearing = ({
    hearingDocumentIsInVbms,
    onHearingDocumentChange,
    form9Type,
    onTypeOfForm9Change,
    hearingType,
    onHearingTypeChange,
    match
}) => {
    debugger;
    return <div>
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Confirm Hearing</h2>

        <div>
          {hearingCheckText}
        </div>

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

/**
 * Creates a component that's connected to the Redux store
 * using the state & dispatch map functions and the
 * ConfirmHearing function.
 */
const ConfirmHearing = connect(
  mapStateToProps,
  mapDispatchToProps
)(_ConfirmHearing)

export default ConfirmHearing;
