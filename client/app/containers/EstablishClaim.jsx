import React, { PropTypes } from 'react';
import ApiUtil from '../util/ApiUtil';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import DropDown from '../components/DropDown';
import Checkbox from '../components/Checkbox';
import DateSelector from '../components/DateSelector';
import Button from '../components/Button';

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

export const REVIEW_PAGE = 0;
export const FORM_PAGE = 1;

export default class EstablishClaim extends React.Component {
  constructor(props) {
    super(props);

     // Set initial state on page render
    this.state = {
      allowPoa: false,
      claimLabel: CLAIM_LABEL_OPTIONS[0],
      gulfWar: false,
      loading: false,
      modifier: MODIFIER_OPTIONS[0],
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
      window.location.reload(true);
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
      page
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
    let { loading } = this.state;


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
                linkStyle={true}
              />
            </div>
          }
          <Button
            name="Cancel"
            onClick={this.handleCancelTask}
            linkStyle={true}
          />
        </div>
      </div>
    );
  }
}

EstablishClaim.propTypes = {
  task: PropTypes.object.isRequired
};
