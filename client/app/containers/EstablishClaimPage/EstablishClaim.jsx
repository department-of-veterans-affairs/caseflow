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

export const REVIEW_PAGE = 0;
export const FORM_PAGE = 1;

export default class EstablishClaim extends BaseForm {
  constructor(props) {
    super(props);

    let decisionType = this.props.task.appeal.decision_type;

    // Set initial state on page render
    this.state = {
      cancelModal: {
        cancelFeedback: new FormField(
          '',
          requiredValidator('Please enter an explanation.')
        )
      },
      cancelModalDisplay: false,
      form: {
        allowPoa: new FormField(false),
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
      modalSubmitLoading: false,
      page: REVIEW_PAGE,
      reviewForm: {
        decisionType: new FormField(decisionType)
      },
      specialIssueModalDisplay: false
    };
  }

  handleSubmit = (event) => {
    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;

    event.preventDefault();
    handleAlertClear();

    this.formValidating();

    if (!this.validateFormAndSetErrors(this.state.form)) {
      return;
    }

    this.setState({
      loading: true
    });

    // We have to add in the claimLabel separately, since it is derived from
    // the form value on the review page.
    let data = {
      claim: ApiUtil.convertToSnakeCase({
        ...this.getFormValues(this.state.form),
        claimLabel: this.getClaimTypeFromDecision()
      })
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

  getClaimTypeFromDecision = () => {
    if (this.state.reviewForm.decisionType.value === 'Remand') {
      return '170RMDAMC - AMC-Remand';
    } else if (this.state.reviewForm.decisionType.value === 'Partial Grant') {
      return '170PGAMC - AMC-Partial Grant';
    } else if (this.state.reviewForm.decisionType.value === 'Full Grant') {
      return '172BVAG - BVA Grant';
    }
    throw new RangeError("Invalid deicion type value");
  }

  handleFinishCancelTask = () => {
    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;
    let data = {
      feedback: this.state.cancelModal.cancelFeedback.value
    };

    handleAlertClear();

    if (!this.validateFormAndSetErrors(this.state.cancelModal)) {
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
        cancelModalDisplay: false,
        modalSubmitLoading: false
      });
    });
  }

  handleCancelModalClose = () => {
    this.setState({
      cancelModalDisplay: false
    });
  }

  handleSpecialIssueModalClose = () => {
    this.setState({
      specialIssueModalDisplay: false
    });
  }

  handleCancelTask = () => {
    this.setState({
      cancelModalDisplay: true
    });
  }

  handleCancelTaskForSpecialIssue = () => {
    this.setState({
      cancelModalDisplay: true,
      specialIssueModalDisplay: false

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
      cancelModalDisplay,
      specialIssueModalDisplay,
      modalSubmitLoading
    } = this.state;

    return (
      <div>
        { this.isReviewPage() && Review.render.call(this) }
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
        {cancelModalDisplay && <Modal
        buttons={[
          { classNames: ["cf-btn-link"],
            name: '\u00AB Go Back',
            onClick: this.handleCancelModalClose
          },
          { classNames: ["usa-button", "usa-button-secondary"],
            loading: modalSubmitLoading,
            name: 'Cancel EP Establishment',
            onClick: this.handleFinishCancelTask
          }
        ]}
        visible={true}
        closeHandler={this.handleCancelModalClose}
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
            onChange={this.handleFieldChange('cancelModal', 'cancelFeedback')}
            required={true}
            {...this.state.cancelModal.cancelFeedback}
          />
        </Modal>}
        {specialIssueModalDisplay && <Modal
            buttons={[
              { classNames: ["cf-btn-link"],
                name: '\u00AB Close',
                onClick: this.handleSpecialIssueModalClose
              },
              { classNames: ["usa-button", "usa-button-secondary"],
                loading: modalSubmitLoading,
                name: 'Cancel Claim Establishment',
                onClick: this.handleCancelTaskForSpecialIssue
              }
            ]}
            visible={true}
            closeHandler={this.handleSpecialIssueModalClose}
            title="Special Issue Grant">
          <p>
            You selected a special issue category not handled by AMO. Special
            issue cases cannot be processed in caseflow at this time. Please
            select <b>Cancel Claim Establishment</b> and proceed to process
            this case manually in VACOLS.
          </p>
        </Modal>}
      </div>
    );
  }
}

EstablishClaim.propTypes = {
  task: PropTypes.object.isRequired
};
