import React from 'react';
import { Link } from 'react-router-dom';
import LoadingContainer from '../components/LoadingContainer';
import RadioField from '../components/RadioField';

const hearingChangeQuestion = "Was a hearing cancellation or request added after 09/01/2017?";
const hearingChangeAnswers = ["Yes", "No"];

const typeOfAppealQuestion = `Caseflow found the document below, labeled as a Form 9,
from the appellant's eFolder. What type of substantive appeal is it?`;
const typeOfAppealAnswers = ["Form 9", "Statement in lieu of Form 9"];

const typeOfHearingQuestion = `Which box did the appellant select for the Optional
Board Hearing question above? Depending on the Form 9, this may be Question 8 or Question 10.`;
const typeOfHearingAnswers = [
  'A. I do not want an optional board hearing',
  'B. I want a hearing by videoconference at a local VA office.',
  'C. I want a hearing in Washington, DC.',
  'D. I want a hearing at a local VA office.',
  'No box selected.']

// TODO: refactor to use shared components where helpful
const ConfirmHearing = ({ match }) => {
  return <div>
    <div className="cf-app-segment cf-app-segment--alt">
      <h2>Confirm Hearing</h2>

      <div>
        Check the appellant's eFolder for a hearing cancellation or request added after 09/01/2017,
        the date the Form 9 (or statement in lieu of Form 9) was uploaded.
      </div>

      <RadioField name={hearingChangeQuestion}
        displayRequired={true}
        options={hearingChangeAnswers}/>

      <RadioField name={typeOfAppealQuestion}
        displayRequired={true}
        options={typeOfAppealAnswers}/>

      <LoadingContainer>
        <iframe
          aria-label="The PDF embedded here is not accessible. Please use the above
            link to download the PDF and view it in a PDF reader. Then use the
            buttons below to go back and make edits or upload and certify
            the document."
          className="cf-doc-embed cf-iframe-with-loading"
          title="Form8 PDF"
          src={`/certifications/${match.params.vacols_id}/form9_pdf`}>
        </iframe>
      </LoadingContainer>

      <RadioField name={typeOfHearingQuestion}
          options={typeOfHearingAnswers}
          displayRequired={true}/>
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

export default ConfirmHearing;
