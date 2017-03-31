/* eslint-disable max-lines */

import React, { PropTypes } from 'react';
import ApiUtil from '../../util/ApiUtil';
import StringUtil from '../../util/StringUtil';
import ROUTING_INFORMATION from '../../constants/Routing';
import SPECIAL_ISSUES from '../../constants/SpecialIssues';
import specialIssueFilters from '../../constants/SpecialIssueFilters';
import BaseForm from '../BaseForm';

import { createEstablishClaimStore } from '../../establishClaim/reducers/store';

import Modal from '../../components/Modal';
import TextareaField from '../../components/TextareaField';
import FormField from '../../util/FormField';
import requiredValidator from '../../util/validators/RequiredValidator';
import dateValidator from '../../util/validators/DateValidator';
import { formatDate } from '../../util/DateUtil';
import EstablishClaimDecision from './EstablishClaimDecision';
import EstablishClaimForm from './EstablishClaimForm';
import EstablishClaimNote from './EstablishClaimNote';
import EstablishClaimEmail from './EstablishClaimEmail';
import EstablishClaimProgressBar from './EstablishClaimProgressBar';
import AssociatePage from './EstablishClaimAssociateEP';

import { createHashHistory } from 'history';
import { Provider } from 'react-redux';

export const DECISION_PAGE = 'decision';
export const ASSOCIATE_PAGE = 'associate';
export const FORM_PAGE = 'form';
export const NOTE_PAGE = 'review';
export const EMAIL_PAGE = 'email';

export const FULL_GRANT = 'Full Grant';
export const PARTIAL_GRANT = 'Partial Grant';
export const REMAND = 'Remand';


export const END_PRODUCT_INFO = {
  'ARC': {
    'Full Grant': ['172BVAG', 'BVA Grant'],
    'Partial Grant': ['170PGAMC', 'ARC-Partial Grant'],
    'Remand': ['170RMDAMC', 'ARC-Remand']
  },
  'Routed': {
    'Full Grant': ['172BVAG', 'BVA Grant'],
    'Partial Grant': ['170RBVAG', 'Remand with BVA Grant'],
    'Remand': ['170RMD', 'Remand']
  }
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

// This page is used by AMC to establish claims. This is
// the last step in the appeals process, and is after the decsion
// has been made. By establishing an EP, we ensure the appeal
// has properly been "handed off" to the right party for adjusting
// the veteran's benefits
export default class EstablishClaim extends BaseForm {
  constructor(props) {
    super(props);
    this.store = createEstablishClaimStore(props);
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
          requiredValidator('Please enter an explanation')
        )
      },
      cancelModalDisplay: false,
      claimForm: {
        // This is the decision date that gets mapped to the claim's creation date
        date: new FormField(
          formatDate(this.props.task.appeal.serialized_decision_date),
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
      history: createHashHistory(),
      loading: false,
      modalSubmitLoading: false,
      page: DECISION_PAGE,
      showNotePageAlert: false,
      specialIssues: {},
      specialIssuesEmail: '',
      specialIssuesRegionalOffice: ''
    };
  }

  defaultPage() {
    if (this.props.task.aasm_state === 'reviewed') {
      // Force navigate to the note page on initial component mount
      // when the task is in reviewed state. This means that they have
      // already been saved in the database, but the user navigated
      // back to the page before the task was complete.
      return NOTE_PAGE;
    }

    // Force navigate to the review page on initial component mount
    // This ensures they are not mid-flow
    return DECISION_PAGE;
  }

  containsRoutedSpecialIssues = () => {
    return specialIssueFilters.routedSpecialIssues().some((issue) => {
      return this.store.getState().specialIssues[issue.specialIssue].value;
    });
  }

  containsRoutedOrRegionalOfficeSpecialIssues = () => {
    return specialIssueFilters.routedOrRegionalSpecialIssues().some((issue) => {
      return this.store.getState().specialIssues[issue.specialIssue || issue].value;
    });
  }

  componentDidMount() {
    let { history } = this.state;

    history.listen((location) => {
      // If we are on the note page and you try to move to
      // a previous page in the flow then we bump you back
      // to the note page.
      if (this.state.page === NOTE_PAGE &&
        location.pathname.substring(1) !== NOTE_PAGE) {
        this.handlePageChange(NOTE_PAGE);
        this.setState({
          showNotePageAlert: true
        });
      } else {
        this.setState({
          page: location.pathname.substring(1) || DECISION_PAGE
        });
      }
    });

    history.replace(this.defaultPage());
  }

  reloadPage = () => {
    window.location.href = window.location.pathname + window.location.search;
  }

  shouldReviewAfterEndProductCreate = () => {
    return this.containsRoutedOrRegionalOfficeSpecialIssues();
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
        // Hold on to your hats... We want to show the note page if we either
        // have a VBMS note, VACOLS note, or both. We have a VBMS note whenever
        // there are routable special issues. We have a VACOLS note whenever
        // the grant is not a full grant. This checks for both of those, and
        // if no note needs to be shown, submits from the note page.
        if (this.shouldReviewAfterEndProductCreate()) {
          this.setState({
            loading: false
          });
          this.handlePageChange(NOTE_PAGE);
        } else {
          this.handleNotePageSubmit(null);
        }
      }, () => {
        this.setState({
          loading: false
        });
        handleAlert(
          'error',
          'System Error',
          'Something went wrong on our end. We were not able to create an End Product.' +
          ' Please try again later.'
        );
      });
  }

  getRoutingType = () => {
    let stationOfJurisdiction = this.state.claimForm.stationOfJurisdiction.value;

    return stationOfJurisdiction === '397 - ARC' ? "ARC" : "Routed";
  }

  getClaimTypeFromDecision = () => {
    let decisionType = this.state.reviewForm.decisionType.value;
    let values = END_PRODUCT_INFO[this.getRoutingType()][decisionType];

    if (!values) {
      throw new RangeError("Invalid decision type value");
    }

    return values;
  }

  handleFinishCancelTask = () => {
    let { id } = this.props.task;
    let data = {
      feedback: this.state.cancelModal.cancelFeedback.value
    };

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
      cancelModalDisplay: true
    });
  }

  handlePageChange = (page) => {
    this.state.history.push(page);
    // Scroll to the top of the page on a page change
    window.scrollTo(0, 0);
  }

  isDecisionPage() {
    return this.state.page === DECISION_PAGE;
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

  isNotePage() {
    return this.state.page === NOTE_PAGE;
  }

  isEmailPage() {
    return this.state.page === EMAIL_PAGE;
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

    if (this.state.reviewForm.decisionType.value === FULL_GRANT) {
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

  handleDecisionPageSubmit = () => {
    this.setStationState();

    this.setState({
      loading: true
    });

    let data = ApiUtil.convertToSnakeCase({
      specialIssues: this.prepareSpecialIssues()
    });

    return ApiUtil.put(`/dispatch/establish-claim/${this.props.task.id}/update-appeal`,
      { data }).then(() => {

        this.setState({
          loading: false
        });

        if (!this.willCreateEndProduct()) {
          if (this.state.reviewForm.decisionType.value === FULL_GRANT) {
            this.setUnhandledSpecialIssuesEmailAndRegionalOffice();
            this.handlePageChange(EMAIL_PAGE);
          } else {
            this.handlePageChange(NOTE_PAGE);
          }
        } else if (this.shouldShowAssociatePage()) {
          this.handlePageChange(ASSOCIATE_PAGE);
        } else {
          this.handlePageChange(FORM_PAGE);
        }

      });
  }

  handleFormPageSubmit = () => {
    this.handleSubmit();
  }

  handleNotePageSubmit = (vacolsNote) => {
    let { handleAlert, handleAlertClear, task } = this.props;

    handleAlertClear();

    this.setState({
      loading: true
    });

    let data = ApiUtil.convertToSnakeCase({
      vacolsNote
    });

    return ApiUtil.post(`/dispatch/establish-claim/${task.id}/review-complete`, { data }).
      then(() => {
        this.reloadPage();
      }, () => {
        handleAlert(
        'error',
        'Error',
        'There was an error while routing the current claim. Please try again later'
      );
        this.setState({
          loading: false
        });
      });
  }

  handleEmailPageSubmit = () => {
    let { handleAlert, handleAlertClear, task } = this.props;

    handleAlertClear();

    this.setState({
      loading: true
    });

    let data = ApiUtil.convertToSnakeCase({
      emailRoId: this.getSpecialIssuesRegionalOfficeCode(),
      emailRecipient: this.getSpecialIssuesEmail().join(', ')
    });

    return ApiUtil.post(`/dispatch/establish-claim/${task.id}/email-complete`, { data }).
      then(() => {
        this.reloadPage();
      }, () => {
        handleAlert(
        'error',
        'Error',
        'There was an error while completing the task. Please try again later'
        );
        this.setState({
          loading: false
        });
      });
  };

  handleNoEmailPageSubmit = () => {
    let { handleAlert, handleAlertClear, task } = this.props;

    handleAlertClear();

    this.setState({
      loading: true
    });

    return ApiUtil.post(`/dispatch/establish-claim/${task.id}/no-email-complete`).
    then(() => {
      this.reloadPage();
    }, () => {
      handleAlert(
        'error',
        'Error',
        'There was an error while completing the task. Please try again later'
      );

      this.setState({
        loading: false
      });
    });
  };

  handleAssociatePageSubmit = () => {
    this.handlePageChange(FORM_PAGE);
  }

  handleBackToDecisionReview = () => {
    this.handlePageChange(DECISION_PAGE);
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
    stateObject.claimForm.stationOfJurisdiction.value = '397 - ARC';
    // Go through the special issues, and for any regional issues, set SOJ to RO
    specialIssueFilters.regionalSpecialIssues().forEach((issue) => {
      if (this.store.getState().specialIssues[issue.specialIssue]) {
        stateObject.claimForm.stationOfJurisdiction.value =
          this.getStationOfJurisdiction();
      }
    });
    // Go through all the special issues, this time looking for routed issues
    specialIssueFilters.routedSpecialIssues().forEach((issue) => {
      if (this.store.getState().specialIssues[issue.specialIssue]) {
        stateObject.claimForm.stationOfJurisdiction.value = issue.stationOfJurisdiction;
      }
    });
    this.setState({
      stateObject
    });
  }

  getSpecialIssuesEmail() {
    if (this.state.specialIssuesEmail === 'PMC') {
      return this.getEmailFromConstant(ROUTING_INFORMATION.PMC);
    } else if (this.state.specialIssuesEmail === 'COWC') {
      return this.getEmailFromConstant(ROUTING_INFORMATION.COWC);
    } else if (this.state.specialIssuesEmail === 'education') {
      return this.getEmailFromConstant(ROUTING_INFORMATION.EDUCATION);
    }

    return this.state.specialIssuesEmail;
  }

  getEmailFromConstant(constant) {
    let regionalOfficeKey = this.props.task.appeal.regional_office_key;

    return ROUTING_INFORMATION.codeToEmailMapper[constant[regionalOfficeKey]];
  }

  getCityAndState(regionalOfficeKey) {
    if (!regionalOfficeKey) {
      return null;
    }

    return `${regionalOfficeKey} - ${
      this.props.regionalOfficeCities[regionalOfficeKey].city}, ${
      this.props.regionalOfficeCities[regionalOfficeKey].state}`;
  }

  getSpecialIssuesRegionalOffice() {
    return this.getCityAndState(
      this.getSpecialIssuesRegionalOfficeCode(this.state.specialIssuesRegionalOffice)
    );
  }

  getSpecialIssuesRegionalOfficeCode() {
    if (this.state.specialIssuesRegionalOffice === 'PMC') {
      return this.getRegionalOfficeFromConstant(ROUTING_INFORMATION.PMC);
    } else if (this.state.specialIssuesRegionalOffice === 'COWC') {
      return this.getRegionalOfficeFromConstant(ROUTING_INFORMATION.COWC);
    } else if (this.state.specialIssuesRegionalOffice === 'education') {
      return this.getRegionalOfficeFromConstant(ROUTING_INFORMATION.EDUCATION);
    } else if (!this.state.specialIssuesRegionalOffice) {
      return null;
    }

    return this.state.specialIssuesRegionalOffice;
  }

  getRegionalOfficeFromConstant(constant) {
    let regionalOfficeKey = this.props.task.appeal.regional_office_key;

    return constant[regionalOfficeKey];
  }

  getStationOfJurisdiction() {
    let stationKey = this.props.task.appeal.station_key;
    let regionalOfficeKey = this.props.task.appeal.regional_office_key;

    return `${stationKey} - ${
        this.props.regionalOfficeCities[regionalOfficeKey].city}, ${
        this.props.regionalOfficeCities[regionalOfficeKey].state}`;
  }

  prepareSpecialIssues() {
    // The database column names must be less than 63 characters
    // so we shorten all of the keys in our hash before we send
    // them to the backend.
    let shortenedObject = {};
    let formValues = ApiUtil.convertToSnakeCase(
      this.getFormValues(this.store.getState().specialIssues)
    );

    Object.keys(formValues).forEach((key) => {
      shortenedObject[key.substring(0, 60)] = formValues[key];
    });

    return shortenedObject;
  }

  stationOfJurisdictionCode() {
    return this.state.claimForm.stationOfJurisdiction.value.substring(0, 3);
  }

  prepareData() {
    let claim = this.getFormValues(this.state.claimForm);

    claim.stationOfJurisdiction = this.stationOfJurisdictionCode();

    // We have to add in the claimLabel separately, since it is derived from
    // the form value on the review page.
    let endProductInfo = this.getClaimTypeFromDecision();

    return ApiUtil.convertToSnakeCase({
      claim: {
        ...claim,
        endProductCode: endProductInfo[0],
        endProductLabel: endProductInfo[1]
      }
    });
  }


  setUnhandledSpecialIssuesEmailAndRegionalOffice = () => {
    if (this.containsRoutedSpecialIssues()) {
      return;
    }

    specialIssueFilters.unhandledSpecialIssues().forEach((issue) => {
      if (this.store.getState().specialIssues[issue.specialIssue].value) {
        this.setState({
          // If there are multiple unhandled special issues, we'll route
          // to the email address for the last one.
          specialIssuesEmail: issue.unhandled.emailAddress,
          specialIssuesRegionalOffice: issue.unhandled.regionalOffice
        });
      }
    });
  }

  // This returns true if the flow will create an EP or assign to an existing EP
  willCreateEndProduct() {
    let willCreateEndProduct = true;

    // If it contains a routed special issue, allow EP creation even if it
    // contains other unhandled special issues.
    if (this.containsRoutedSpecialIssues()) {
      return true;
    }

    specialIssueFilters.unhandledSpecialIssues().forEach((issue) => {
      if (this.store.getState().specialIssues[issue.specialIssue].value) {
        willCreateEndProduct = false;
      }
    });

    return willCreateEndProduct;
  }

  render() {
    let {
      cancelModalDisplay,
      history,
      modalSubmitLoading,
      specialIssues
    } = this.state;

    let {
      pdfLink,
      pdfjsLink
    } = this.props;

    return (
      <Provider store={this.store}>
        <div>
        <EstablishClaimProgressBar
          isReviewDecision={this.isDecisionPage()}
          isRouteClaim={!this.isDecisionPage()}
        />
        { this.isDecisionPage() &&
        <EstablishClaimDecision
          loading={this.state.loading}
          decisionType={this.state.reviewForm.decisionType}
          handleCancelTask={this.handleCancelTask}
          handleFieldChange={this.handleFieldChange}
          handleSubmit={this.handleDecisionPageSubmit}
          pdfLink={pdfLink}
          pdfjsLink={pdfjsLink}
          specialIssues={specialIssues}
          task={this.props.task}
        />
        }
        { this.isAssociatePage() &&
        <AssociatePage
          loading={this.state.loading}
          endProducts={this.props.task.appeal.non_canceled_end_products_within_30_days}
          task={this.props.task}
          decisionType={this.state.reviewForm.decisionType.value}
          handleAlert={this.props.handleAlert}
          handleAlertClear={this.props.handleAlertClear}
          handleCancelTask={this.handleCancelTask}
          handleSubmit={this.handleAssociatePageSubmit}
          hasAvailableModifers={this.hasAvailableModifers()}
          handleBackToDecisionReview={this.handleBackToDecisionReview}
          history={history}
          specialIssues={ApiUtil.convertToSnakeCase(
              this.getFormValues(this.state.specialIssues))}
        />
        }
        { this.isFormPage() &&
        <EstablishClaimForm
          loading={this.state.loading}
          claimForm={this.state.claimForm}
          claimLabelValue={this.getClaimTypeFromDecision().join(' - ')}
          handleCancelTask={this.handleCancelTask}
          handleSubmit={this.handleFormPageSubmit}
          handleFieldChange={this.handleFieldChange}
          handleBackToDecisionReview={this.handleBackToDecisionReview}
          validModifiers={this.validModifiers()}
        />
        }
        { this.isNotePage() &&
        <EstablishClaimNote
          loading={this.state.loading}
          appeal={this.props.task.appeal}
          handleSubmit={this.handleNotePageSubmit}
          showNotePageAlert={this.state.showNotePageAlert}
          specialIssues={specialIssues}
          displayVacolsNote={this.state.reviewForm.decisionType.value !== FULL_GRANT}
          displayVbmsNote={this.containsRoutedOrRegionalOfficeSpecialIssues()}
        />
        }
        { this.isEmailPage() &&
        <EstablishClaimEmail
          loading={this.state.loading}
          appeal={this.props.task.appeal}
          handleCancelTask={this.handleCancelTask}
          handleEmailSubmit={this.handleEmailPageSubmit}
          handleNoEmailSubmit={this.handleNoEmailPageSubmit}
          regionalOffice={this.getSpecialIssuesRegionalOffice()}
          regionalOfficeEmail={this.getSpecialIssuesEmail()}
          specialIssues={specialIssues}
          handleBackToDecisionReview={this.handleBackToDecisionReview}
        />
        }
        {cancelModalDisplay && <Modal
          buttons={[
            { classNames: ["cf-modal-link", "cf-btn-link"],
              name: 'Close',
              onClick: this.handleModalClose('cancelModalDisplay')
            },
            { classNames: ["usa-button", "usa-button-secondary"],
              loading: modalSubmitLoading,
              name: 'Stop processing claim',
              onClick: this.handleFinishCancelTask
            }
          ]}
          visible={true}
          closeHandler={this.handleModalClose('cancelModalDisplay')}
          title="Stop Processing Claim">
          <p>
            If you click the <b>Stop processing claim </b>
            button below your work will not be
            saved and an EP will not be created for this claim.
          </p>
          <p>
            Please tell us why you have chosen to discontinue processing this claim.
          </p>
          <TextareaField
            label="Explanation"
            name="Explanation"
            onChange={this.handleFieldChange('cancelModal', 'cancelFeedback')}
            required={true}
            {...this.state.cancelModal.cancelFeedback}
          />
        </Modal>}
        </div>
      </Provider>
    );
  }
}

EstablishClaim.propTypes = {
  regionalOfficeCities: PropTypes.object.isRequired,
  task: PropTypes.object.isRequired
};

/* eslint-enable max-lines */
