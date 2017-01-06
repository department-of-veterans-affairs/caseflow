import React, { PropTypes } from 'react';
import ApiUtil from '../../util/ApiUtil';

import BaseForm from '../BaseForm';

import Modal from '../../components/Modal';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';
import FormField from '../../util/FormField';
import requiredValidator from '../../util/validators/RequiredValidator';
import dateValidator from '../../util/validators/DateValidator';
import { formatDate } from '../../util/DateUtil';
import * as Review from './EstablishClaimReview';
import * as Form from './EstablishClaimForm';
import * as Associate from './EstablishClaimAssociateEP';

export const REVIEW_PAGE = 0;
export const ASSOCIATE_PAGE = 1;
export const FORM_PAGE = 2;

export default class EstablishClaim extends BaseForm {
  constructor(props) {
    super(props);

    // Set initial state on page render
    this.state = {
      cancelModal: false,
      form: {
        allowPoa: new FormField(false),
        claimLabel: new FormField(
          Form.CLAIM_LABEL_OPTIONS[0],
          requiredValidator('Please enter the EP & Claim Label.')
          ),
        decisionDate: new FormField(
          formatDate(this.props.task.appeal.decision_date),
          [
            requiredValidator('Please enter the Decision Date.'),
            dateValidator()
          ]
          ),
        gulfWar: new FormField(false),
        modifier: new FormField(Form.MODIFIER_OPTIONS[0]),
        poa: new FormField(Form.POA[0]),
        poaCode: new FormField(''),
        segmentedLane: new FormField(
          Form.SEGMENTED_LANE_OPTIONS[0],
          requiredValidator('Please enter a Segmented Lane.')
          ),
        suppressAcknowledgement: new FormField(false)
      },
      loading: false,
      modal: {
        cancelFeedback: new FormField(
          '',
          requiredValidator('Please enter an explanation.')
          )
      },
      modalSubmitLoading: false,
      page: ASSOCIATE_PAGE
    };
  }

  handleSubmit = (event) => {
    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;

    event.preventDefault();
    handleAlertClear();

    if (!this.validateFormAndSetErrors(this.state.form)) {
      this.setErrors = true;

      return;
    }

    this.setState({
      loading: true
    });

    let data = {
      claim: ApiUtil.convertToSnakeCase(this.getFormValues(this.state.form))
    };

    return ApiUtil.post(`/dispatch/establish-claim/${id}/perform`, { data }).then(() => {
      window.location.reload();
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

    if (!this.validateFormAndSetErrors(this.state.modal)) {
      return;
    }

    this.setState({
      modalSubmitLoading: true
    });

    return ApiUtil.patch(`/tasks/${id}/cancel`, { data }).then(() => {
      window.location.reload();
    }, () => {
      handleAlert(
        'error',
        'Error',
        'There was an error while cancelling the current claim. Please try again later'
      );
      this.setState({
        cancelModal: false,
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

  handlePageChange = (page) => {
    this.setState({
      page
    });

    // Scroll to the top of the page on a page change
    window.scrollTo(0, 0);
  }

  isReviewPage() {
    return this.state.page === REVIEW_PAGE;
  }

  isAssociatePage() {
    return this.state.page === ASSOCIATE_PAGE;
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
      cancelModal,
      modalSubmitLoading
    } = this.state;

    return (
      <div>
        { this.isReviewPage() && Review.render.call(this) }
        { this.isAssociatePage() && Associate.render.call(this) }
        { this.isFormPage() && Form.render.call(this) }

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
          { classNames: ["cf-btn-link"],
            name: '\u00AB Go Back',
            onClick: this.handleModalClose
          },
          { classNames: ["usa-button", "usa-button-secondary"],
            loading: modalSubmitLoading,
            name: 'Cancel EP Establishment',
            onClick: this.handleFinishCancelTask
          }
        ]}
        visible={true}
        closeHandler={this.handleModalClose}
        title="Cancel EP Establishment">
          <p>
            If you click the <b>Cancel EP Establishment</b>
            button below your work will not be
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
