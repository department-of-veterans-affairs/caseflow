import React, { PropTypes } from 'react';
import ApiUtil from '../util/ApiUtil';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import DropDown from '../components/DropDown';
import Checkbox from '../components/Checkbox';
import DateSelector from '../components/DateSelector';
import Modal from '../components/Modal';
import Button from '../components/Button';
import TextareaField from '../components/TextareaField'
const POA = [
  'None',
  'VSO',
  'Private'
];
const CLAIM_LABEL_OPTIONS = [
  ' ',
  '172BVAG - BVA Grant',
  '170PGAMC - AMC-Partial Grant',
  '170RMDAMC - AMC-Remand'
];
const MODIFIER_OPTIONS = [
  '170',
  '172'
];
const SEGMENTED_LANE_OPTIONS = [
  'Core (National)',
  'Spec Ops (National)'
];

let MODAL_REQUIRED = {
  cancelFeedback: {display: false, message: 'Please enter an Explanation.'}
};

export const REVIEW_PAGE = 0;
export const FORM_PAGE = 1;

export default class EstablishClaim extends React.Component {
  constructor(props) {
    super(props);

     // Set initial state on page render
    this.state = {
      allowPoa: false,
      cancelModal: false,
      cancelFeedback: '',
      claimLabel: CLAIM_LABEL_OPTIONS[0],
      gulfWar: false,
      loading: false,
      modifier: MODIFIER_OPTIONS[0],
      modalSubmitLoading: false,
      page: REVIEW_PAGE,
      poa: POA[0],
      poaCode: '',
      segmentedLane: SEGMENTED_LANE_OPTIONS[0],
      suppressAcknowledgement: false
    };
  }

  handleSubmit = (event) => {
    this.setState({
      loading: true
    });

    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;

    event.preventDefault();
    handleAlertClear();

    let data = {
      claim: ApiUtil.convertToSnakeCase(this.state)
    };

    return ApiUtil.post(`/dispatch/establish-claim/${id}/perform`, { data }).then(() => {
      window.location.href = `/dispatch/establish-claim/${id}/complete`;
    }, () => {
      this.setState({
        loading: false
      });
      handleAlert(
        'error',
        'Error',
        'There was an error while submitting the current claim. Please try again later'
      );
    });
  }

  validateRequiredFields = (required) => {
    let validationPassed = true;
    Object.keys(required).forEach((key) => {
      required[key].display = this.state[key].length == 0;
      validationPassed = validationPassed && !required[key].display;
    });
    return validationPassed;
  }

  handleFinishCancelTask = () => {
    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;
    let data = { 
      feedback: this.state.cancelFeedback
    };
    handleAlertClear();

    if (!this.validateRequiredFields(MODAL_REQUIRED)) {
      return;
    }

    this.setState({
      modalSubmitLoading: true
    })

    return ApiUtil.patch(`/tasks/${id}/cancel`, { data }).then(() => {
      window.location.href = '/dispatch/establish-claim';
    }, () => {
      handleAlert(
        'error',
        'Error',
        'There was an error while cancelling the current claim. Please try again later'
      );
      this.setState({
        cancelModal: false
      });
      this.setState({
        modalSubmitLoading: false
      })
    });
  }

  handleModalClose = () => {
    this.setState({
      cancelModal: false
    });
  }

  handleCancelTask = () => {
    this.setState({
      cancelModal: true
    });
  }

  handleChange = (key, value) => {
    let output = {};

    output[key] = value;
    this.setState(output);
  }

  handlePoaChange = (event) => {
    this.setState({
      poa: event.target.value
    });
  }

  handlePoaCodeChange = (event) => {
    this.setState({
      poaCode: event.target.value
    });
  }

  hasPoa() {
    return this.state.poa === 'VSO' || this.state.poa === 'Private';
  }

  handleCancelFeedbackChange = (event) => {
    this.setState({
      cancelFeedback: event.target.value
    });
  }

  // TODO (mdbenjam): This is not being used right now, remove if
  // we decide this is not how we want the modifier to work.
  static getModifier(claim) {
    let modifier = MODIFIER_OPTIONS[0];

    MODIFIER_OPTIONS.forEach((option) => {
      if (claim.startsWith(option)) {
        modifier = option;
      }
    });

    return modifier;
  }

  handlePageChange = (page) => {
    this.setState({
      page
    });
  }

  form() {
    let { task } = this.props;
    let { appeal } = task;
    let {
      allowPoa,
      claimLabel,
      gulfWar,
      modifier,
      poa,
      poaCode,
      segmentedLane,
      suppressAcknowledgement
    } = this.state;


    return (
      <form noValidate>
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Create End Product</h1>
          <TextField
           label="Benefit Type"
           name="BenefitType"
           value="C&P Live"
           readOnly={true}
          />
          <TextField
           label="Payee"
           name="Payee"
           value="00 - Veteran"
           readOnly={true}
          />
          <DropDown
           label="Claim Label"
           name="claimLabel"
           options={CLAIM_LABEL_OPTIONS}
           onChange={this.handleChange}
           value={claimLabel}
          />
          <DropDown
           label="Modifier"
           name="modifier"
           options={MODIFIER_OPTIONS}
           onChange={this.handleChange}
           value={modifier}
          />
          <DateSelector
           label="Decision Date"
           name="decisionDate"
           readOnly={true}
           value={appeal.decision_date}
          />
          <DropDown
           label="Segmented Lane"
           name="segmentedLane"
           options={SEGMENTED_LANE_OPTIONS}
           onChange={this.handleChange}
           value={segmentedLane}
          />
          <TextField
           label="Station"
           name="Station"
           value="499 - National Work Queue"
           readOnly={true}
          />
          <RadioField
           label="POA"
           name="POA"
           selected={poa}
           options={POA}
           onChange={this.handlePoaChange}
          />
          {this.hasPoa() && <div><TextField
           label="POA Code"
           name="POACode"
           value={poaCode}
           onChange={this.handlePoaCodeChange}
          />
          <Checkbox
           label="Allow POA Access to Documents"
           name="allowPoa"
           value={allowPoa}
           onChange={this.handleChange}
          /></div>}
          <Checkbox
           label="Gulf War Registry Permit"
           name="gulfWar"
           value={gulfWar}
           onChange={this.handleChange}
          />
          <Checkbox
           label="Suppress Acknowledgement Letter"
           name="suppressAcknowledgement"
           value={suppressAcknowledgement}
           onChange={this.handleChange}
          />
        </div>
      </form>
    );
  }

  review() {
    let { pdfLink, pdfjsLink } = this.props;

    return (
      <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Review Decision</h2>
          Review the final decision from VBMS below to determine the next step.
        </div>
        {
        /* This link is here for 508 compliance, and shouldn't be visible to sighted
         users. We need to allow non-sighted users to preview the Decision. Adobe Acrobat
         is the accessibility standard and is used across gov't, so we'll recommend it
         for now. The usa-sr-only class will place an element off screen without
         affecting its placement in tab order, thus making it invisible onscreen
         but read out by screen readers. */
        }
        <a
          className="usa-sr-only"
          id="sr-download-link"
          href={pdfLink}
          download
          target="_blank">
          "The PDF viewer in your browser may not be accessible. Click to download
          the Decision PDF so you can preview it in a reader with accessibility features
          such as Adobe Acrobat.
        </a>
        <a className="usa-sr-only" href="#establish-claim-buttons">
          If you are using a screen reader and have downloaded and verified the Decision
          PDF, click this link to skip past the browser PDF viewer to the
          establish-claim buttons.
        </a>

        <iframe
          aria-label="The PDF embedded here is not accessible. Please use the above
            link to download the PDF and view it in a PDF reader. Then use the buttons
            below to go back and make edits or upload and certify the document."
          className="cf-doc-embed cf-app-segment"
          title="Form8 PDF"
          src={pdfjsLink}>
        </iframe>
      </div>
    );
  }


  isReviewPage() {
    return this.state.page === REVIEW_PAGE;
  }

  isFormPage() {
    return this.state.page === FORM_PAGE;
  }

  handleCreateEndProduct = (event) => {
    if (this.isReviewPage()) {
      this.handlePageChange(FORM_PAGE);
    } else if (this.isFormPage()) {
      this.handleSubmit(event);
    } else {
      throw new RangeError("Invalid page value");
    }
  }

  render() {
    let { 
      loading,
      cancelFeedback,
      cancelModal,
      modalSubmitLoading
    } = this.state;
    console.log(MODAL_REQUIRED);

    return (
      <div>
        { this.isReviewPage() && this.review() }
        { this.isFormPage() && this.form() }

        <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="cf-push-right">
            <a href="#send_to_ro" className="cf-btn-link cf-adjacent-buttons">
              Send to RO
            </a>
            <Button
              name="Create End Product"
              loading={loading}
              onClick={this.handleCreateEndProduct}
            />
          </div>
          { this.isFormPage() &&
            <div className="task-link-row">
              <Button
                name={"\u00ABBack to review"}
                onClick={() => {
                  this.handlePageChange(REVIEW_PAGE);
                } }
                classNames={["cf-btn-link"]}
              />
            </div>
          }
          <Button
            name="Cancel"
            onClick={this.handleCancelTask}
            classNames={["cf-btn-link"]}
          />
        </div>
        {cancelModal && <Modal
        buttons={[
          {name: '\u00AB Go Back', onClick: this.handleModalClose, classNames: ["cf-btn-link"]},
          {name: 'Cancel EP Establishment', onClick: this.handleFinishCancelTask, classNames: ["usa-button", "usa-button-secondary"], loading: modalSubmitLoading}
          ]}
        visible={true}
        closeHandler={this.handleModalClose}
        title="Cancel EP Establishment">
          <p>
            If you click the <b>Cancel EP Establishment</b> button below your work will not be
            saved and the EP for this claim will not be established.
          </p>
          <p>
            Please tell why you are canceling this claim.
          </p>
          <TextareaField
            errorMessage={MODAL_REQUIRED.cancelFeedback.display ? MODAL_REQUIRED.cancelFeedback.message : null}
            label="Cancel Explanation"
            name="Explanation"
            onChange={this.handleCancelFeedbackChange}
            required={true}
            value={cancelFeedback}
          />
        </Modal>}
      </div>
    );
  }
}

EstablishClaim.propTypes = {
  task: PropTypes.object.isRequired
};
