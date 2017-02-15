/* eslint-disable max-lines */

import React, { PropTypes } from 'react';
import ApiUtil from '../../util/ApiUtil';

import BaseForm from '../BaseForm';

import Modal from '../../components/Modal';
import TextareaField from '../../components/TextareaField';
import FormField from '../../util/FormField';
import requiredValidator from '../../util/validators/RequiredValidator';
import dateValidator from '../../util/validators/DateValidator';
import { formatDate } from '../../util/DateUtil';
import EstablishClaimReview, * as Review from './EstablishClaimReview';
import EstablishClaimForm from './EstablishClaimForm';
import AssociatePage from './EstablishClaimAssociateEP';

import { createHashHistory } from 'history';

export const REVIEW_PAGE = 'review';
export const ASSOCIATE_PAGE = 'associate';
export const FORM_PAGE = 'form';


export const END_PRODUCT_INFO = {
  'Full Grant': ['172BVAG', 'BVA Grant'],
  'Partial Grant': ['170PGAMC', 'AMC-Partial Grant'],
  'Remand': ['170RMDAMC', 'AMC-Remand']
};

const FULL_GRANT_MODIFIER_OPTIONS = [
  '172'
];

const PARTIAL_GRANT_MODIFIER_OPTIONS = [
  '170',
  '171',
  '175',
  '176',
  '177',
  '178',
  '179'
];

const SPECIAL_ISSUES = Review.SPECIAL_ISSUE_FULL.concat(Review.SPECIAL_ISSUE_PARTIAL);

// This page is used by AMC to establish claims. This is
// the last step in the appeals process, and is after the decsion
// has been made. By establishing an EP, we ensure the appeal
// has properly been "handed off" to the right party for adjusting
// the veteran's benefits
export default class EstablishClaim extends BaseForm {
  constructor(props) {
    super(props);

    let decisionType = this.props.task.appeal.decision_type;

    // Set initial state on page render

    // The reviewForm decisionType is needed in the state first since
    // it is used to calculate the validModifiers
    this.state = {
      reviewForm: {
        decisionType: new FormField(decisionType)
      }
    };

    let validModifiers = this.validModifiers();

    this.state = {
      ...this.state,
      cancelModal: {
        cancelFeedback: new FormField(
          '',
          requiredValidator('Please enter an explanation.')
        )
      },
      cancelModalDisplay: false,
      claimForm: {
        // This is the decision date that gets mapped to the claim's creation date
        date: new FormField(
          formatDate(this.props.task.appeal.decision_date),
          [
            requiredValidator('Please enter the Decision Date.'),
            dateValidator()
          ]
        ),
        endProductModifier: new FormField(validModifiers[0]),
        gulfWarRegistry: new FormField(false),
        stationOfJurisdiction: new FormField('397 - AMC'),
        suppressAcknowledgementLetter: new FormField(false)
      },
      handleFinishCancelTask: null,
      history: createHashHistory(),
      loading: false,
      modalSubmitLoading: false,
      page: REVIEW_PAGE,
      specialIssueModalDisplay: false,
      specialIssues: {}
    };
    SPECIAL_ISSUES.forEach((issue) => {
      this.state.specialIssues[ApiUtil.convertToCamelCase(issue)] = new FormField(false);
    });
  }


  componentDidMount() {
    let { history } = this.state;

    history.listen((location) => {
      this.setState({
        page: location.pathname.substring(1) || REVIEW_PAGE
      });
    });

    // Force navigate to the review page on initial component mount
    // This ensures they are not mid-flow
    history.replace(REVIEW_PAGE);
  }

  reloadPage = () => {
    window.location.href = window.location.pathname + window.location.search;
  }

  handleSubmit = () => {
    let { handleAlert, handleAlertClear, task } = this.props;

    handleAlertClear();

    this.formValidating();

    if (!this.validateFormAndSetErrors(this.state.claimForm)) {
      return;
    }

    this.setState({
      loading: true
    });

    let data = this.prepareData();

    return ApiUtil.post(`/dispatch/establish-claim/${task.id}/perform`, { data }).
      then(() => {
        this.reloadPage();
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

  handleFinishCancelTask = (sendSpeicalIssues) => () => {
    let { id } = this.props.task;
    let data = {
      feedback: this.state.cancelModal.cancelFeedback.value,
      specialIssues: null
    };

    if (sendSpeicalIssues) {
      data.specialIssues = ApiUtil.convertToSnakeCase(
        this.getFormValues(this.state.specialIssues));
    }

    this.props.handleAlertClear();

    if (!this.validateFormAndSetErrors(this.state.cancelModal)) {
      return;
    }

    this.setState({
      modalSubmitLoading: true
    });

    data = ApiUtil.convertToSnakeCase(data);

    return ApiUtil.patch(`/dispatch/establish-claim/${id}/cancel`, { data }).then(() => {
      this.reloadPage();
    }, () => {
      this.props.handleAlert(
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

  handleModalClose = (modal) => () => {
    let stateObject = {};

    stateObject[modal] = false;
    this.setState(stateObject);
  };

  handleCancelTask = () => {
    this.setState({
      cancelModalDisplay: true,
      handleFinishCancelTask: this.handleFinishCancelTask(false)
    });
  }

  handleCancelTaskForSpecialIssue = () => {
    this.setState({
      cancelModalDisplay: true,
      handleFinishCancelTask: this.handleFinishCancelTask(true),
      specialIssueModalDisplay: false
    });
  }

  handlePageChange = (page) => {
    this.state.history.push(page);
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
   * This function gets the set of unused modifiers. For a full grant, only one
   * modifier, 172, is valid. For partial grants, 170, 171, 175, 176, 177, 178, 179
   * are all potentially valid. This removes any modifiers that have already been
   * used in previous EPs.
   */
  validModifiers = () => {
    let modifiers = [];
    let endProducts = this.props.task.appeal.pending_eps;

    if (this.state.reviewForm.decisionType.value === 'Full Grant') {
      modifiers = FULL_GRANT_MODIFIER_OPTIONS;
    } else {
      modifiers = PARTIAL_GRANT_MODIFIER_OPTIONS;
    }

    let modifierHash = endProducts.reduce((modifierObject, endProduct) => {
      modifierObject[endProduct.end_product_type_code] = true;

      return modifierObject;
    }, {});

    return modifiers.filter((modifier) => !modifierHash[modifier]);
  }

  hasAvailableModifers = () => this.validModifiers().length > 0

  handleDecisionTypeChange = (value) => {
    this.handleFieldChange('reviewForm', 'decisionType')(value);

    let stateObject = {};
    let modifiers = this.validModifiers();

    stateObject.claimForm = { ...this.state.claimForm };
    stateObject.claimForm.endProductModifier.value = modifiers[0];

    this.setState(stateObject);
  }

  handleReviewPageSubmit = () => {
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

  handleAssociatePageSubmit = () => {
    this.handlePageChange(FORM_PAGE);
  }

  /*
   * This function takes the special issues from the review page and sets the station
   * of jurisdiction in the form page. Special issues that all go to the same spot are
   * defined in the constant ROUTING_SPECIAL_ISSUES. Special issues that go back to the
   * regional office are defined in REGIONAL_OFFICE_SPECIAL_ISSUES.
   */
  setStationState() {
    let stateObject = this.state;

    // default needs to be reset in case the user has navigated back in the form
    stateObject.claimForm.stationOfJurisdiction.value = '397 - AMC';

    Review.REGIONAL_OFFICE_SPECIAL_ISSUES.forEach((issue) => {
      if (this.state.specialIssues[issue].value) {
        stateObject.claimForm.stationOfJurisdiction.value =
          this.getStationOfJurisdiction();
      }
    });
    Review.ROUTING_SPECIAL_ISSUES.forEach((issue) => {
      if (this.state.specialIssues[issue.specialIssue].value) {
        stateObject.claimForm.stationOfJurisdiction.value = issue.stationOfJurisdiction;
      }
    });
    this.setState({
      stateObject
    });
  }

  getStationOfJurisdiction() {
    let stationKey = this.props.task.appeal.station_key;
    let regionalOfficeKey = this.props.regionalOfficeStations[stationKey];

    return `${stationKey} - ${
        this.props.regionalOfficeCities[regionalOfficeKey].city}, ${
        this.props.regionalOfficeCities[regionalOfficeKey].state}`;
  }

  prepareData() {
    let stateObject = this.state;

    stateObject.claimForm.stationOfJurisdiction.value =
        stateObject.claimForm.stationOfJurisdiction.value.substring(0, 3);

    this.setState({
      stateObject
    });

    // We have to add in the claimLabel separately, since it is derived from
    // the form value on the review page.
    let endProductInfo = this.getClaimTypeFromDecision();


    return ApiUtil.convertToSnakeCase({
      claim: ApiUtil.convertToSnakeCase({
        ...this.getFormValues(this.state.claimForm),
        endProductCode: endProductInfo[0],
        endProductLabel: endProductInfo[1]
      }),
      specialIssues: ApiUtil.convertToSnakeCase(
        this.getFormValues(this.state.specialIssues))
    });
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
      history,
      modalSubmitLoading,
      specialIssueModalDisplay,
      specialIssues
    } = this.state;

    let {
      pdfLink,
      pdfjsLink
    } = this.props;

    return (
      <div>
        { this.isReviewPage() &&
          <EstablishClaimReview
            decisionType={this.state.reviewForm.decisionType}
            handleCancelTask={this.handleCancelTask}
            handleCancelTaskForSpecialIssue={this.handleCancelTaskForSpecialIssue}
            handleDecisionTypeChange={this.handleDecisionTypeChange}
            handleFieldChange={this.handleFieldChange}
            handleModalClose={this.handleModalClose}
            handleSubmit={this.handleReviewPageSubmit}
            pdfLink={pdfLink}
            pdfjsLink={pdfjsLink}
            specialIssueModalDisplay={specialIssueModalDisplay}
            specialIssues={specialIssues}
            task={this.props.task}
          />
        }
        { this.isAssociatePage() &&
          <AssociatePage
            endProducts={this.props.task.appeal.non_canceled_end_products_within_30_days}
            task={this.props.task}
            decisionType={this.state.reviewForm.decisionType.value}
            handleAlert={this.props.handleAlert}
            handleAlertClear={this.props.handleAlertClear}
            handleCancelTask={this.handleCancelTask}
            handleSubmit={this.handleAssociatePageSubmit}
            hasAvailableModifers={this.hasAvailableModifers()}
            history={history}
            specialIssues={ApiUtil.convertToSnakeCase(
              this.getFormValues(this.state.specialIssues))}
          />
        }
        { this.isFormPage() &&
          <EstablishClaimForm
            claimForm={this.state.claimForm}
            claimLabelValue={this.getClaimTypeFromDecision().join(' - ')}
            handleCancelTask={this.handleCancelTask}
            handleSubmit={this.handleSubmit}
            handleFieldChange={this.handleFieldChange}
            loading={loading}
            validModifiers={this.validModifiers()}
          />
        }

        {cancelModalDisplay && <Modal
          buttons={[
            { classNames: ["cf-modal-link", "cf-btn-link"],
              name: '\u00AB Go Back',
              onClick: this.handleModalClose('cancelModalDisplay')
            },
            { classNames: ["usa-button", "usa-button-secondary"],
              loading: modalSubmitLoading,
              name: 'Cancel EP Establishment',
              onClick: this.state.handleFinishCancelTask
            }
          ]}
          visible={true}
          closeHandler={this.handleModalClose('cancelModalDisplay')}
          title="Cancel EP Establishment">
          <p>
            If you click the <b>Cancel EP Establishment </b>
            button below your work will not be
            saved and the EP for this claim will not be established.
          </p>
          <p>
            Please tell why you are canceling the establishment of this EP.
          </p>
          <TextareaField
            label="Cancel Explanation"
            name="Explanation"
            onChange={this.handleFieldChange('cancelModal', 'cancelFeedback')}
            required={true}
            {...this.state.cancelModal.cancelFeedback}
          />
        </Modal>}
      </div>
    );
  }
}

EstablishClaim.propTypes = {
  regionalOfficeCities: PropTypes.object.isRequired,
  regionalOfficeStations: PropTypes.object.isRequired,
  task: PropTypes.object.isRequired
};

/* eslint-enable max-lines */
