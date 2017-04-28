import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';
import * as certificationActions from './actions/Certification';
import * as actions from './actions/ConfirmHearing';
import { Redirect } from 'react-router-dom';


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

const hearingChangeAnswers = [
  { displayText: 'Yes',
    value: Constants.vbmsHearingDocument.FOUND },
  { displayText: 'No',
    value: Constants.vbmsHearingDocument.NOT_FOUND }
];

const hearingChangeFoundQuestion = `What did the appellant request
in the document you found?`;
const hearingChangeFoundAnswers = [
  {
    displayText: 'They cancelled their hearing request.',
    value: Constants.hearingPreferences.HEARING_CANCELLED
  },
  {
    displayText: 'They requested a board hearing via videoconference.',
    value: Constants.hearingPreferences.VIDEO
  },
  {
    displayText: 'They requested a board hearing in Washington, DC.',
    value: Constants.hearingPreferences.WASHINGTON_DC
  },
  {
    displayText: 'They requested a board hearing at a local VA office.',
    value: Constants.hearingPreferences.TRAVEL_BOARD
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
  value: Constants.hearingPreferences.NO_HEARING_DESIRED
}, {
  displayText: 'B. I want a hearing by videoconference at a local VA office.',
  value: Constants.hearingPreferences.VIDEO
}, {
  displayText: 'C. I want a hearing in Washington, DC.',
  value: Constants.hearingPreferences.WASHINGTON_DC
}, {
  displayText: 'D. I want a hearing at a local VA office.',
  value: Constants.hearingPreferences.TRAVEL_BOARD
}, {
  displayText: 'No box selected.',
  value: Constants.hearingPreferences.NO_BOX_SELECTED
}];

const informalForm9HearingQuestion = `What optional board hearing preference,
if any, did the appellant request?`;
const informalForm9HearingAnswers = [{
  displayText: `Does not want an optional board hearing
  or did not mention a board hearing.`,
  value: Constants.hearingPreferences.NO_HEARING_DESIRED
}, {
  displayText: 'Wants a board hearing and did not specify what type.',
  value: Constants.hearingPreferences.HEARING_TYPE_NOT_SPECIFIED
}, {
  displayText: 'Wants a board hearing by videoconference.',
  value: Constants.hearingPreferences.VIDEO
}, {
  displayText: 'Wants a board hearing in Washington, DC.',
  value: Constants.hearingPreferences.WASHINGTON_DC
}, {
  displayText: 'Wants a board hearing at their regional office.',
  value: Constants.hearingPreferences.TRAVEL_BOARD
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

class UnconnectedConfirmHearing extends React.Component {
  // TODO: updating state in ComponentWillMount is
  // sometimes thought of as an anti-pattern.
  // is there a better way to do this?
  componentWillMount() {
    this.props.updateProgressBar();
  }

  componentWillUnmount() {
    this.props.resetState();
  }

  getValidationErrors() {
    let {
      hearingDocumentIsInVbms,
      hearingPreference,
      form9Type
    } = this.props;

    const erroredFields = [];

    if (!hearingPreference && hearingDocumentIsInVbms) {
      erroredFields.push('hearingDocumentIsInVbms');
    }

    if (!hearingDocumentIsInVbms && !form9Type) {
      erroredFields.push('hearingChangeQuestion');
    }

    return erroredFields;
  }

  onClickContinue() {
    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      this.props.onContinueClickFailed();

      return;
    }

    // Sets continueClicked to false for the next page.
    this.props.onContinueClickSuccess();

    this.props.certificationUpdateStart({
      hearingDocumentIsInVbms: this.props.hearingDocumentIsInVbms,
      form9Type: this.props.form9Type,
      hearingPreference: this.props.hearingPreference,
      vacolsId: this.props.match.params.vacols_id
    });
  }

  /* eslint-disable max-statements */
  render() {
    let { hearingDocumentIsInVbms,
      onHearingDocumentChange,
      form9Type,
      form9Date,
      onTypeOfForm9Change,
      hearingPreference,
      onHearingPreferenceChange,
      loading,
      updateFailed,
      updateSucceeded,
      continueClicked,
      certificationId,
      match
    } = this.props;

    if (updateSucceeded) {
      return <Redirect
        to={`/certifications/${match.params.vacols_id}/sign_and_certify`}/>;
    }

    if (updateFailed) {
      // TODO: add real error handling and validated error states etc.
      return <div>500 500 error error</div>;
    }


    const hearingCheckText = <span>Check the appellant's eFolder for a hearing
    cancellation or request added after <strong>{form9Date}</strong>, the date the Form 9
    (or statement in lieu of Form 9) was uploaded.</span>;

    const hearingChangeQuestion = <span>Was a hearing cancellation or request
     added after <strong>{form9Date}</strong>?</span>;

    const shouldDisplayHearingChangeFound =
      hearingDocumentIsInVbms === Constants.vbmsHearingDocument.FOUND;
    const shouldDisplayTypeOfForm9Question =
      hearingDocumentIsInVbms === Constants.vbmsHearingDocument.NOT_FOUND;

    const form9IsFormal = form9Type === Constants.form9Types.FORMAL_FORM9;
    const form9IsInformal = form9Type === Constants.form9Types.INFORMAL_FORM9;

    const shouldDisplayFormalForm9Question = shouldDisplayTypeOfForm9Question &&
      form9IsFormal;
    const shouldDisplayInformalForm9Question = shouldDisplayTypeOfForm9Question &&
      form9IsInformal;

    // if the form input is not valid and the user has already tried to click continue,
    // disable the continue button until the validation errors are fixed.
    let disableContinue = (Boolean(this.getValidationErrors().length && continueClicked));

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
            hearingPreferenceChangeRadioField

            which would be a connected component with
            direct access to the Redux store.
          */}
          <RadioField name="hearingChangeQuestion"
            label={hearingChangeQuestion}
            required={true}
            options={hearingChangeAnswers}
            value={hearingDocumentIsInVbms}
            onChange={onHearingDocumentChange}/>

          {
            shouldDisplayHearingChangeFound &&
            <RadioField name={hearingChangeFoundQuestion}
              required={true}
              options={hearingChangeFoundAnswers}
              value={hearingPreference}
              onChange={onHearingPreferenceChange}/>
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
              value={hearingPreference}
              required={true}
              onChange={onHearingPreferenceChange}/>
          }

          {
            shouldDisplayInformalForm9Question &&
            <RadioField name={informalForm9HearingQuestion}
              options={informalForm9HearingAnswers}
              value={hearingPreference}
              required={true}
              onChange={onHearingPreferenceChange}/>
          }
        </div>
      <Footer
        disableContinue={disableContinue}
        loading={loading}
        onClickContinue={this.onClickContinue.bind(this)}
        certificationId={certificationId}
      />
    </div>;
  }
  /* eslint-enable max-statements */
}

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
const mapDispatchToProps = (dispatch) => ({
  updateProgressBar: () => dispatch(actions.updateProgressBar()),

  resetState: () => dispatch(certificationActions.resetState()),

  onHearingDocumentChange: (hearingDocumentIsInVbms) => {
    dispatch(actions.onHearingDocumentChange(hearingDocumentIsInVbms));
  },

  onContinueClickFailed: () => dispatch(certificationActions.onContinueClickFailed()),

  onContinueClickSuccess: () => dispatch(certificationActions.onContinueClickSuccess()),

  onTypeOfForm9Change: (form9Type) => dispatch(actions.onTypeOfForm9Change(form9Type)),

  onHearingPreferenceChange: (hearingPreference) => dispatch(actions.onHearingPreferenceChange(hearingPreference)),

  certificationUpdateStart: (props) => {
    dispatch(actions.certificationUpdateStart(props, dispatch));
  }
});

/*
 * This function tells us which parts of the global
 * application state should be passed in as props to
 * the rendered component.
 */

const mapStateToProps = (state) => ({
  hearingDocumentIsInVbms: state.hearingDocumentIsInVbms,
  form9Type: state.form9Type,
  form9Date: state.form9Date,
  continueClicked: state.continueClicked,
  certificationId: state.certificationId,
  hearingPreference: state.hearingPreference,
  loading: state.loading,
  updateSucceeded: state.updateSucceeded,
  updateFailed: state.updateFailed
});

/*
 * Creates a component that's connected to the Redux store
 * using the state & dispatch map functions and the
 * ConfirmHearing function.
 */
const ConfirmHearing = connect(
  mapStateToProps,
  mapDispatchToProps
)(UnconnectedConfirmHearing);

ConfirmHearing.propTypes = {
  hearingDocumentIsInVbms: PropTypes.string,
  onHearingDocumentChange: PropTypes.func,
  form9Type: PropTypes.string,
  form9Date: PropTypes.string,
  onTypeOfForm9Change: PropTypes.func,
  hearingPreference: PropTypes.string,
  onHearingPreferenceChange: PropTypes.func,
  match: PropTypes.object.isRequired,
  continueClicked: PropTypes.bool,
  certificationId: PropTypes.number
};

export default ConfirmHearing;
