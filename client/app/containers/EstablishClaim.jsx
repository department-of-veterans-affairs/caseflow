import React, { PropTypes } from 'react';
import ApiUtil from '../util/ApiUtil';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import DropDown from '../components/DropDown';
import Checkbox from '../components/Checkbox';
import DateSelector from '../components/DateSelector';

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

const REVIEW_PAGE = 0;
const FORM_PAGE = 1;

export default class EstablishClaim extends React.Component {
    constructor(props) {
    super(props);

     // Set initial state on page render
    this.state = {
      allowPoa: false,
      claimLabel: CLAIM_LABEL_OPTIONS[0],
      gulfWar: false,
      modifier: MODIFIER_OPTIONS[0],
      poa: POA[0],
      poaCode: '',
      segmentedLane: SEGMENTED_LANE_OPTIONS[0],
      suppressAcknowledgement: false,
      page: REVIEW_PAGE
    };
  }

  handleSubmit = (event) => {
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
      handleAlert(
        'error',
        'Error',
        'There was an error while submitting the current claim. Please try again later'
      );
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
      page: page
    });
  }

  handleCancelTask = () => {
    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;

    handleAlertClear();

    return ApiUtil.patch(`/tasks/${id}/cancel`).then(() => {
      window.location.href = '/dispatch/establish-claim';
    }, () => {
      handleAlert(
        'error',
        'Error',
        'There was an error while cancelling the current claim. Please try again later'
      );
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
      <form className="cf-form" noValidate>
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
    let { pdf_link, pdfjs_link } = this.props;
    return (
      <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Review Decision</h2>
          Review the final decision from VBMS below to determine the next step.
        </div>

        {/* This link is here for 508 compliance, and shouldn't be visible to sighted users. We need to allow non-sighted users to preview the Decision. Adobe Acrobat is the accessibility standard and is used across gov't, so we'll recommend it for now. The usa-sr-only class will place an element off screen without
         affecting its placement in tab order, thus making it invisible onscreen
         but read out by screen readers. */} 
        <a className="usa-sr-only" id="sr-download-link" href={pdf_link} download target="_blank">"The PDF viewer in your browser may not be accessible. Click to download the Decision PDF so you can preview it in a reader with accessibility features such as Adobe Acrobat.</a>
        <a className="usa-sr-only" href="#establish-claim-buttons"> If you are using a screen reader and have downloaded and verified the Decision PDF, click this link to skip past the browser PDF viewer to the establish-claim buttons.</a>

        <iframe 
          aria-label="The PDF embedded here is not accessible. Please use the above link to download the PDF and view it in a PDF reader. Then use the buttons below to go back and make edits or upload and certify the document."
          className="cf-doc-embed cf-app-segment"
          title="Form8 PDF"
          src={pdfjs_link}>
        </iframe>
      </div>
    );
  }

  handleCreateEndProduct = (event) => {
    if (this.state.page == REVIEW_PAGE) {
      this.handlePageChange(FORM_PAGE);
    } else if (this.state.page == FORM_PAGE) {
      this.handleSubmit(event);
    } else {
      throw "Invalid page state";
    }
  }

  render() {
    return (
      <div>
        { this.state.page == REVIEW_PAGE && this.review() }
        { this.state.page == FORM_PAGE && this.form() }

        <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="cf-push-right">
            <a href="#send_to_ro" className="cf-btn-link cf-adjacent-buttons">Send to RO</a>
            <button 
              type="submit"
              className="usa-button usa-button-blue cf-submit cf-adjacent-buttons"
              onClick={this.handleCreateEndProduct}>
              Create End Product
            </button>
          </div>
          { this.state.page == FORM_PAGE && 
            <div className="task-link-row">
              <button
                onClick={() => {this.handlePageChange(REVIEW_PAGE)} }
                className="cf-btn-link">
                {'\u00AB'}Back to review
              </button>
            </div>
          }
          <button className="cf-btn-link" onClick={this.handleCancelTask}>
            Cancel
          </button>
        </div>
      </div>
    );
  }
}

EstablishClaim.propTypes = {
  task: PropTypes.object.isRequired
};
