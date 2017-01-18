/* eslint-disable max-lines */

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

export const END_PRODUCT_INFO = {
  'Full Grant': ['172BVAG', 'BVA Grant'],
  'Partial Grant': ['170PGAMC', 'AMC-Partial Grant'],
  'Remand': ['170RMDAMC', 'AMC-Remand']
};

// This page is used by AMC to establish claims. This is
// the last step in the appeals process, and is after the decsion
// has been made. By establishing an EP, we ensure the appeal
// has properly been "handed off" to the right party for adjusting
// the veteran's benefits
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
        // This is the decision date that gets mapped to the claim's creation date
        date: new FormField(
          formatDate(this.props.task.appeal.decision_date),
          [
            requiredValidator('Please enter the Decision Date.'),
            dateValidator()
          ]
        ),
        endProductModifier: new FormField(Form.MODIFIER_OPTIONS[0]),
        gulfWarRegistry: new FormField(false),
        poa: new FormField(Form.POA[0]),
        poaCode: new FormField(''),
        segmentedLane: new FormField(
          Form.SEGMENTED_LANE_OPTIONS[0],
          requiredValidator('Please enter a Segmented Lane.')
        ),
        stationOfJurisdiction: new FormField('397 - AMC'),
        suppressAcknowledgementLetter: new FormField(false)
      },
      loading: false,
      modalSubmitLoading: false,
      page: REVIEW_PAGE,
      reviewForm: {
        decisionType: new FormField(decisionType)
      },
      specialIssueModalDisplay: false,
      specialIssues: {}
    };
    specialIssues.forEach((issue) => {
      this.state.specialIssues[ApiUtil.convertToCamelCase(issue)] = new FormField(false);
    });
  }

  handleSubmit = (event) => {
    let { handleAlert, handleAlertClear, task } = this.props;

    event.preventDefault();
    handleAlertClear();

    this.formValidating();

    if (!this.validateFormAndSetErrors(this.state.form)) {
      return;
    }

    this.setState({
      loading: true
    });

    let data = this.prepareData();

    return ApiUtil.post(`/dispatch/establish-claim/${task.id}/perform`, { data }).
      then(() => {
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
    let values = END_PRODUCT_INFO[this.state.reviewForm.decisionType.value];

    if (!values) {
      throw new RangeError("Invalid deicion type value");
    }

    return values;
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

  handleModalClose = function (modal) {
    return () => {
      let stateObject = {};

      stateObject[modal] = false;
      this.setState(stateObject);
    };
  };

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

  /*
   * This function acts as a router on the end product form. If the user
   * is on the review page, it goes to the review page validation function.
   * That checks to make sure only valid special issues are checked and either
   * displays an error modal or moves the user on to the next page. If the user
   * is on the associate page, they move onto the form page. If the user is on
   * the form page, their form is submitted, and they move to the success page.
   */
  handleCreateEndProduct = (event) => {
    if (this.isReviewPage()) {
      this.handleReviewPageSubmit();
    } else if (this.isAssociatePage()) {
      this.handlePageChange(FORM_PAGE);
    } else if (this.isFormPage()) {
      this.handleSubmit(event);
    } else {
      throw new RangeError("Invalid page value");
    }
  }

  handleReviewPageSubmit() {
    this.setStationState();
    if (!this.validateReviewPageSubmit()) {
      this.setState({
        specialIssueModalDisplay: true
      });
    } else if (this.shouldShowAssociatePage()) {
      this.handlePageChange(ASSOCIATE_PAGE);
    } else {
      this.handlePageChange(FORM_PAGE);
    }
  }

  /*
   * This function takes the special issues from the review page and sets the station
   * of jurisdiction in the form page. Special issues that all go to the same spot are
   * defined in the constant ROUTING_SPECIAL_ISSUES. Special issues that go back to the
   * regional office are defined in REGIONAL_OFFICE_SPECIAL_ISSUES.
   */
  setStationState() {
    let stateObject = this.state;

    Review.ROUTING_SPECIAL_ISSUES.forEach((issue) => {
      if (this.state.specialIssues[issue.specialIssue].value) {
        stateObject.form.stationOfJurisdiction.value = issue.stationOfJurisdiction;
      }
    });
    Review.REGIONAL_OFFICE_SPECIAL_ISSUES.forEach((issue) => {
      if (this.state.specialIssues[issue].value) {
        stateObject.form.stationOfJurisdiction.value =
          this.props.task.appeal.regional_office_key;
      }
    });
    this.setState({
      stateObject
    });
  }

  prepareData() {
    let stateObject = this.state;

    stateObject.form.stationOfJurisdiction.value =
        stateObject.form.stationOfJurisdiction.value.substring(0, 3);

    this.setState({
      stateObject
    });

    // We have to add in the claimLabel separately, since it is derived from
    // the form value on the review page.
    let endProductInfo = this.getClaimTypeFromDecision();


    return {
      claim: ApiUtil.convertToSnakeCase({
        ...this.getFormValues(this.state.form),
        endProductCode: endProductInfo[0],
        endProductLabel: endProductInfo[1]
      })
    };
  }

  validateReviewPageSubmit() {
    let validOutput = true;

    Review.UNHANDLED_SPECIAL_ISSUES.forEach((issue) => {
      if (this.state.specialIssues[ApiUtil.convertToCamelCase(issue)].value) {
        validOutput = false;
      }
    });

    return validOutput;
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
            task = {this.props.task}
            handleAlert = {this.props.handleAlert}
            handleAlertClear = {this.props.handleAlertClear}
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
              onClick: this.handleModalClose('cancelModalDisplay')
            },
            { classNames: ["usa-button", "usa-button-secondary"],
              loading: modalSubmitLoading,
              name: 'Cancel EP Establishment',
              onClick: this.handleFinishCancelTask
            }
          ]}
          visible={true}
          closeHandler={this.handleModalClose('cancelModalDisplay')}
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
              onClick: this.handleModalClose('specialIssueModalDisplay')
            },
            { classNames: ["usa-button", "usa-button-secondary"],
              name: 'Cancel Claim Establishment',
              onClick: this.handleCancelTaskForSpecialIssue
            }
          ]}
          visible={true}
          closeHandler={this.handleModalClose('specialIssueModalDisplay')}
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

/* eslint-enable max-lines */
