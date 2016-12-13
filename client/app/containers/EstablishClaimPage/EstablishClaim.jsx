import React, { PropTypes } from 'react';
import ApiUtil from '../util/ApiUtil';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import DropDown from '../components/DropDown';
import Checkbox from '../components/Checkbox';
import DateSelector from '../components/DateSelector';
import Modal from '../components/Modal';
import Button from '../components/Button';
import TextareaField from '../components/TextareaField';
import { FormField, handleFieldChange } from '../util/FormField';
import requiredValidator from '../util/validators/RequiredValidator';
import review from './EstablishClaimReview';
import form from './EstablishClaimForm';

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
  cancelFeedback: { display: false, message: 'Please enter an Explanation.' }
};

export const REVIEW_PAGE = 0;
export const FORM_PAGE = 1;


export default class EstablishClaim extends React.Component {
  constructor(props) {
    super(props);

    this.handleFieldChange = handleFieldChange(this);

    // Set initial state on page render
    this.state = {
      form: {
        allowPoa: new FormField(false),
        claimLabel: new FormField(CLAIM_LABEL_OPTIONS[0]),
        gulfWar: new FormField(false),
        modifier: new FormField(MODIFIER_OPTIONS[0]),
        poa: new FormField(POA[0]),
        poaCode: new FormField(''),
        segmentedLane: new FormField(SEGMENTED_LANE_OPTIONS[0]),
        suppressAcknowledgement: new FormField(false)
      },
      modal: {
        cancelFeedback: new FormField('', requiredValidator('Please enter an Explanation.'))
      },
      cancelModal: false,
      loading: false,
      modalSubmitLoading: false,
      page: REVIEW_PAGE
    };
    console.log("this one");
    console.log(...this.state.form);
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

  handleFinishCancelTask = () => {
    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;
    let data = {
      feedback: this.state.modal.cancelFeedback.value
    };

    handleAlertClear();

    let allValid = true;

    Object.keys(this.state.modal).forEach((key) => {
      let errorMessage = this.state.modal[key].validator(this.state.modal[key].value);
      let modal = { ...this.state.modal };

      modal[key].errorMessage = errorMessage;

      this.setState({
        modal
      });

      allValid = allValid && errorMessage === null;
    });

    if (!allValid) {
      return;
    }


    this.setState({
      modalSubmitLoading: true
    });

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
      });
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

  hasPoa() {
    return this.state.form.poa.value === 'VSO' || this.state.form.poa.value === 'Private';
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
           onChange={this.handleFieldChange('form', 'claimLabel')}
           {...this.state.form.claimLabel}
          />
          <DropDown
           label="Modifier"
           name="modifier"
           options={MODIFIER_OPTIONS}
           onChange={this.handleFieldChange('form', 'modifier')}
           {...this.state.form.modifier}
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
           onChange={this.handleFieldChange('form', 'segmentedLane')}
           {...this.state.form.segmentedLane}
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
           options={POA}
           onChange={this.handleFieldChange('form', 'poa')}
           {...this.state.form.poa}
          />
          {this.hasPoa() && <div><TextField
           label="POA Code"
           name="POACode"
           {...this.state.form.poaCode}
           onChange={this.handleFieldChange('form', 'poaCode')}
          />
          <Checkbox
           label="Allow POA Access to Documents"
           name="allowPoa"
           {...this.state.form.allowPoa}
           onChange={this.handleFieldChange('form', 'allowPoa')}
          /></div>}
          <Checkbox
           label="Gulf War Registry Permit"
           name="gulfWar"
           {...this.state.form.gulfWar}
           onChange={this.handleFieldChange('form', 'gulfWar')}
          />
          <Checkbox
           label="Suppress Acknowledgement Letter"
           name="suppressAcknowledgement"
           {...this.state.form.suppressAcknowledgement}
           onChange={this.handleFieldChange('form', 'suppressAcknowledgement')}
          />
        </div>
      </form>
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
          { name: '\u00AB Go Back', onClick: this.handleModalClose, classNames: ["cf-btn-link"] },
          { name: 'Cancel EP Establishment', onClick: this.handleFinishCancelTask, classNames: ["usa-button", "usa-button-secondary"], loading: modalSubmitLoading }
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
            label="Cancel Explanation"
            name="Explanation"
            onChange={this.handleFieldChange('modal', 'cancelFeedback')}
            required={true}
            {...this.state.modal.cancelFeedback}
          />
        </Modal>}
      </div>
    );
  }
}

EstablishClaim.propTypes = {
  task: PropTypes.object.isRequired
};
