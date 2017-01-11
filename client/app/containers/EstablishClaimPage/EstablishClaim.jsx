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
import AssociatePage from './EstablishClaimAssociateEP';

export const REVIEW_PAGE = 0;
export const ASSOCIATE_PAGE = 1;
export const FORM_PAGE = 2;

export default class EstablishClaim extends BaseForm {
  constructor(props) {
    super(props);

    let decisionType = this.props.task.appeal.decision_type;
    let specialIssues = Review.SPECIAL_ISSUE_FULL.concat(Review.SPECIAL_ISSUE_PARTIAL);
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
      specialIssues: {},
      specialIssueModalDisplay: false
    };
    specialIssues.forEach((issue) => {
      this.state.specialIssues[issue] = new FormField(false);
    });
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

  shouldShowAssociatePage() {
    return this.props.task.appeal.non_canceled_end_products_within_30_days &&
      this.props.task.appeal.non_canceled_end_products_within_30_days.length > 0;
  }

  isAssociatePage() {
    return this.state.page === ASSOCIATE_PAGE;
  }

  isFormPage() {
    return this.state.page === FORM_PAGE;
  }

  handleCreateEndProduct = (event) => {
    if (this.isReviewPage()) {
      if (this.shouldShowAssociatePage()) {
        this.handlePageChange(ASSOCIATE_PAGE);
      } else {
        this.handlePageChange(FORM_PAGE);
      }
    } else if (this.isAssociatePage()) {
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
        { this.isAssociatePage() &&
          <AssociatePage
            endProducts={this.props.task.appeal.non_canceled_end_products_within_30_days}
          />
        }
        { this.isFormPage() && Form.render.call(this) }

        <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="cf-push-right">
            <a href="#send_to_ro" className="cf-btn-link cf-adjacent-buttons">
              Send to RO
            </a>
            <Button
              name={this.isAssociatePage() ? "Create New EP" : "Create End Product"}
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
