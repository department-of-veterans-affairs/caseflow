/* eslint-disable max-lines */

import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';

import ApiUtil from '../../util/ApiUtil';
import WindowUtil from '../../util/WindowUtil';
import specialIssueFilters from '../../constants/SpecialIssueFilters';
import {
  FULL_GRANT,
  INCREMENT_MODIFIER_ON_DUPLICATE_EP_ERROR,
  PERFORM_ESTABLISH_CLAIM_START,
  PERFORM_ESTABLISH_CLAIM_FAILURE,
  PERFORM_ESTABLISH_CLAIM_SUCCESS,
  SUBMIT_DECISION_PAGE,
  SUBMIT_DECISION_PAGE_SUCCESS,
  SUBMIT_DECISION_PAGE_FAILURE
} from '../../establishClaim/constants';

// import bootstrapRedux from '../../establishClaim/reducers/bootstrap';
import { validModifiers, getSpecialIssuesEmail, getSpecialIssuesRegionalOffice } from '../../establishClaim/util';
import { getStationOfJurisdiction } from '../../establishClaim/selectors';

import { formatDateStr } from '../../util/DateUtil';
import EstablishClaimDecision from './EstablishClaimDecision';
import EstablishClaimForm from './EstablishClaimForm';
import EstablishClaimNote from './EstablishClaimNote';
import EstablishClaimEmail from './EstablishClaimEmail';
import EstablishClaimProgressBar from './EstablishClaimProgressBar';
import AssociatePage from './EstablishClaimAssociateEP';
import CancelModal from '../../establishClaim/components/CancelModal';

import { createHashHistory } from 'history';

export const DECISION_PAGE = 'decision';
export const ASSOCIATE_PAGE = 'associate';
export const FORM_PAGE = 'form';
export const NOTE_PAGE = 'review';
export const EMAIL_PAGE = 'email';

export const END_PRODUCT_INFO = {
  ARC: {
    'Full Grant': ['070BVAGRARC', 'ARC BVA Grant'],
    'Partial Grant': ['070RMBVAGARC', 'ARC Remand with BVA Grant'],
    Remand: ['070RMNDARC', 'ARC Remand (070)']
  },
  Routed: {
    'Full Grant': ['070BVAGR', 'BVA Grant (070)'],
    'Partial Grant': ['070RMNDBVAG', 'Remand with BVA Grant (070)'],
    Remand: ['070RMND', 'Remand (070)']
  }
};

const CREATE_EP_ERRORS = {
  duplicate_ep: {
    header: 'Unable to assign or create a new EP for this claim',
    body:
      'Please try to create this EP again. If you are still unable ' +
      'to proceed, select Cancel at the bottom of the page to ' +
      'release this claim, and process it outside of Caseflow.'
  },
  task_already_completed: {
    header: 'This task was already completed.',
    body: (
      <span>
        Please return to <a href="/dispatch/establish-claim/">Work History</a> to establish the next claim.
      </span>
    )
  },
  missing_ssn: {
    header: 'The EP for this claim must be created outside Caseflow.',
    body: (
      <span>
        This veteran does not have a social security number, so their claim cannot be established in Caseflow.
        <br />
        Select Cancel at the bottom of the page to release this claim and proceed to process it outside of Caseflow.
      </span>
    )
  },
  bgs_info_invalid: {
    header: 'The EP for this claim must be created outside Caseflow.',
    body: (
      <span>
        The veteran's profile in the corporate database is missing information required by Caseflow.
        <br />
        Select Cancel at the bottom of the page to release this claim and proceed to process it outside of Caseflow.
      </span>
    )
  },
  end_product_invalid: {
    header: 'The EP for this claim must be created outside Caseflow.',
    body: (
      <span>
        Data associated with this claim has not passed our validation. It's likely there is erroneous data associated
        with this claim.
        <br />
        Select Cancel at the bottom of the page to release this claim and proceed to process it outside of Caseflow.
      </span>
    )
  },
  default: {
    header: 'System Error',
    body: [
      'Something went wrong on our end. We were not able to create an End Product. ',
      'Please try again later.'
    ].join('')
  }
};

const BACK_TO_DECISION_REVIEW_TEXT = '< Back to Review Decision';

// This page is used by AMC to establish claims. This is
// the last step in the appeals process, and is after the decsion
// has been made. By establishing an EP, we ensure the appeal
// has properly been "handed off" to the right party for adjusting
// the veteran's benefits
export class EstablishClaim extends React.Component {
  constructor(props) {
    super(props);
    this.history = createHashHistory();

    this.state = {
      ...this.state,
      loading: false,
      endProductCreated: false,
      page: DECISION_PAGE,
      showNotePageAlert: false,
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
    return specialIssueFilters(this.props.featureToggles?.specialIssuesRevamp).routedSpecialIssues().
      some((issue) => {
        return this.props.specialIssues[issue.specialIssue];
      });
  };

  containsRoutedOrRegionalOfficeSpecialIssues = () => {
    return specialIssueFilters(this.props.featureToggles?.specialIssuesRevamp).routedOrRegionalSpecialIssues().
      some((issue) => {
        return this.props.specialIssues[issue.specialIssue || issue];
      });
  };

  componentDidMount() {
    this.history.listen((location) => {
      // If we are on the note page and you try to move to
      // a previous page in the flow then we bump you back
      // to the note page.
      if (
        this.state.page === NOTE_PAGE &&
        location.pathname.substring(1) !== NOTE_PAGE &&
        this.state.endProductCreated
      ) {
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

    this.history.replace(this.defaultPage());
  }

  shouldReviewAfterEndProductCreate = () => {
    return this.containsRoutedOrRegionalOfficeSpecialIssues();
  };

  handleFormPageSubmit = () => {
    const { handleAlert, handleAlertClear, task } = this.props;

    handleAlertClear();

    this.setState({
      loading: true
    });

    const data = this.prepareData();

    this.props.beginPerformEstablishClaim();

    return ApiUtil.post(`/dispatch/establish-claim/${task.id}/perform`, { data }).then(
      () => {
        // Hold on to your hats... We want to show the note page if we either
        // have a VBMS note, VACOLS note, or both. We have a VBMS note whenever
        // there are routable special issues. We have a VACOLS note whenever
        // the grant is not a full grant. This checks for both of those, and
        // if no note needs to be shown, submits from the note page.
        if (this.shouldReviewAfterEndProductCreate()) {
          this.setState({
            loading: false,
            endProductCreated: true
          });
          this.handlePageChange(NOTE_PAGE);
        } else {
          this.handleNotePageSubmit(null);
        }
        this.props.performEstablishClaimSuccess();
      },
      (error) => {
        this.props.performEstablishClaimFailure();
        // eslint-disable-next-line
        const errorMessage = CREATE_EP_ERRORS[error.response.body?.error_code] || CREATE_EP_ERRORS.default;

        const nextModifier = this.validModifiers()[1];

        // eslint-disable-next-line
        if (error.response.body?.error_code === 'duplicate_ep' && nextModifier) {
          this.props.onDuplicateEP(nextModifier);
        }

        this.setState({
          loading: false
        });

        handleAlert('error', errorMessage.header, errorMessage.body);
      }
    );
  };

  getRoutingType = () => {
    let stationOfJurisdiction = getStationOfJurisdiction(
      this.props.specialIssues,
      this.props.task.appeal.station_key,
      this.props.featureToggles?.specialIssuesRevamp
    );

    return stationOfJurisdiction === '397' ? 'ARC' : 'Routed';
  };

  getClaimTypeFromDecision = () => {
    const decisionType = this.props.task.appeal.dispatch_decision_type;
    const values = END_PRODUCT_INFO[this.getRoutingType()][decisionType];

    if (!values) {
      throw new RangeError('Invalid decision type value');
    }

    return values;
  };

  handlePageChange = (page) => {
    this.history.push(page);
    // Scroll to the top of the page on a page change
    window.scrollTo(0, 0);
  };

  isDecisionPage() {
    return this.state.page === DECISION_PAGE;
  }

  shouldShowAssociatePage() {
    return (
      this.props.task.appeal.non_canceled_end_products_within_30_days &&
      this.props.task.appeal.non_canceled_end_products_within_30_days.length > 0
    );
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

  validModifiers = () => {
    return validModifiers(this.props.task.appeal.pending_eps, this.props.task.appeal.dispatch_decision_type);
  };

  hasAvailableModifers = () => this.validModifiers().length > 0;

  handleDecisionPageSubmit = () => {
    const { handleAlert } = this.props;

    this.setState({
      loading: true
    });

    this.props.submitDecisionPage();

    const data = ApiUtil.convertToSnakeCase({
      specialIssues: this.prepareSpecialIssues()
    });

    return ApiUtil.put(`/dispatch/establish-claim/${this.props.task.id}/update-appeal`, { data }).then(
      () => {
        this.setState({
          loading: false
        });

        if (!this.willCreateEndProduct()) {
          if (this.props.task.appeal.dispatch_decision_type === FULL_GRANT) {
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

        this.props.submitDecisionPageSuccess();
      },
      (error) => {
        // eslint-disable-next-line
        const errorMessage = CREATE_EP_ERRORS[error.response.body?.error_code] || CREATE_EP_ERRORS.default;

        this.setState({
          loading: false
        });

        this.props.submitDecisionPageFailure();

        handleAlert('error', errorMessage.header, errorMessage.body);
      }
    );
  };

  handleNotePageSubmit = (vacolsNote) => {
    const { handleAlert, handleAlertClear, task } = this.props;

    handleAlertClear();

    this.setState({
      loading: true
    });

    // We want to trim the vacols note to 280 char. As that is
    // a DB column constraint

    const data = ApiUtil.convertToSnakeCase({
      vacolsNote: vacolsNote && vacolsNote.substring(0, 280)
    });

    return ApiUtil.post(`/dispatch/establish-claim/${task.id}/review-complete`, { data }).then(
      () => {
        WindowUtil.reloadPage();
      },
      () => {
        handleAlert('error', 'Error', 'There was an error while routing the current claim. Please try again later');
        this.setState({
          loading: false
        });
      }
    );
  };

  handleAssociatePageSubmit = () => {
    this.handlePageChange(FORM_PAGE);
  };

  handleBackToDecisionReview = () => {
    this.handlePageChange(DECISION_PAGE);
  };

  formattedDecisionDate = () => {
    return formatDateStr(this.props.task.appeal.serialized_decision_date);
  };

  prepareSpecialIssues() {
    // The database column names must be less than 63 characters
    // so we shorten all of the keys in our hash before we send
    // them to the backend.
    let shortenedObject = {};
    let formValues = ApiUtil.convertToSnakeCase(this.props.specialIssues);

    Object.keys(formValues).forEach((key) => {
      shortenedObject[key.substring(0, 60)] = formValues[key];
    });

    return shortenedObject;
  }

  prepareData() {
    const claim = this.props.establishClaimForm;

    claim.date = this.formattedDecisionDate();
    claim.stationOfJurisdiction = getStationOfJurisdiction(
      this.props.specialIssues,
      this.props.task.appeal.station_key,
      this.props.featureToggles?.specialIssuesRevamp
    );

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

    specialIssueFilters(this.props.featureToggles?.specialIssuesRevamp).unhandledSpecialIssues().
      forEach((issue) => {
        if (this.props.specialIssues[issue.specialIssue]) {
          this.setState({
          // If there are multiple unhandled special issues, we'll route
          // to the email address for the last one.
            specialIssuesEmail: issue.unhandled.emailAddress,
            specialIssuesRegionalOffice: issue.unhandled.regionalOffice
          });
        }
      });
  };

  // This returns true if the flow will create an EP or assign to an existing EP
  willCreateEndProduct() {
    let willCreateEndProduct = true;

    // If it contains a routed special issue, allow EP creation even if it
    // contains other unhandled special issues.
    if (this.containsRoutedSpecialIssues()) {
      return true;
    }

    specialIssueFilters(this.props.featureToggles?.specialIssuesRevamp).unhandledSpecialIssues().
      forEach((issue) => {
        if (this.props.specialIssues[issue.specialIssue]) {
          willCreateEndProduct = false;
        }
      });

    return willCreateEndProduct;
  }

  render() {
    const { pdfLink, pdfjsLink } = this.props;
    const decisionType = this.props.task.appeal.dispatch_decision_type;

    return (
      <div>
        <EstablishClaimProgressBar isReviewDecision={this.isDecisionPage()} isRouteClaim={!this.isDecisionPage()} />
        {this.isDecisionPage() && (
          <EstablishClaimDecision
            loading={this.state.loading}
            decisionType={decisionType}
            handleFieldChange={this.handleFieldChange}
            handleSubmit={this.handleDecisionPageSubmit}
            pdfLink={pdfLink}
            pdfjsLink={pdfjsLink}
            task={this.props.task}
            specialIssuesRevamp={this.props.featureToggles?.specialIssuesRevamp}
          />
        )}
        {this.isAssociatePage() && (
          <AssociatePage
            loading={this.state.loading}
            endProducts={this.props.task.appeal.non_canceled_end_products_within_30_days}
            history={this.history}
            task={this.props.task}
            decisionType={decisionType}
            handleAlert={this.props.handleAlert}
            handleAlertClear={this.props.handleAlertClear}
            handleSubmit={this.handleAssociatePageSubmit}
            hasAvailableModifers={this.hasAvailableModifers()}
            handleBackToDecisionReview={this.handleBackToDecisionReview}
            backToDecisionReviewText={BACK_TO_DECISION_REVIEW_TEXT}
          />
        )}
        {this.isFormPage() && (
          <EstablishClaimForm
            loading={this.state.loading}
            claimLabelValue={this.getClaimTypeFromDecision().join(' - ')}
            decisionDate={this.formattedDecisionDate()}
            handleSubmit={this.handleFormPageSubmit}
            handleFieldChange={this.handleFieldChange}
            handleBackToDecisionReview={this.handleBackToDecisionReview}
            backToDecisionReviewText={BACK_TO_DECISION_REVIEW_TEXT}
            regionalOfficeKey={this.props.task.appeal.regional_office_key}
            regionalOfficeCities={this.props.regionalOfficeCities}
            stationKey={this.props.task.appeal.station_key}
            specialIssuesRevamp={this.props.featureToggles?.specialIssuesRevamp}
            stationOfJurisdiction={getStationOfJurisdiction(
              this.props.specialIssues,
              this.props.task.appeal.station_key,
              this.props.featureToggles?.specialIssuesRevamp
            )}
          />
        )}
        {this.isNotePage() && (
          <EstablishClaimNote
            loading={this.state.loading}
            endProductCreated={this.state.endProductCreated}
            appeal={this.props.task.appeal}
            decisionType={decisionType}
            handleSubmit={this.handleNotePageSubmit}
            handleBackToDecisionReview={this.handleBackToDecisionReview}
            backToDecisionReviewText={BACK_TO_DECISION_REVIEW_TEXT}
            showNotePageAlert={this.state.showNotePageAlert}
            displayVacolsNote={decisionType !== FULL_GRANT}
            displayVbmsNote={this.containsRoutedOrRegionalOfficeSpecialIssues()}
            specialIssuesRevamp={this.props.featureToggles?.specialIssuesRevamp}
          />
        )}
        {this.isEmailPage() && (
          <EstablishClaimEmail
            appeal={this.props.task.appeal}
            handleAlertClear={this.props.handleAlertClear}
            handleAlert={this.props.handleAlert}
            regionalOfficeEmail={getSpecialIssuesEmail(
              this.state.specialIssuesEmail,
              this.props.task.appeal.regional_office_key
            )}
            regionalOffice={getSpecialIssuesRegionalOffice(
              this.state.specialIssuesRegionalOffice,
              this.props.task.appeal.regional_office_key,
              this.props.regionalOfficeCities
            )}
            handleBackToDecisionReview={this.handleBackToDecisionReview}
            backToDecisionReviewText={BACK_TO_DECISION_REVIEW_TEXT}
            specialIssuesRegionalOffice={this.state.specialIssuesRegionalOffice}
            taskId={this.props.task.id}
            specialIssuesRevamp={this.props.featureToggles?.specialIssuesRevamp}
          />
        )}
        <CancelModal
          handleAlertClear={this.props.handleAlertClear}
          handleAlert={this.props.handleAlert}
          taskId={this.props.task.id}
        />
      </div>
    );
  }
}

EstablishClaim.propTypes = {
  regionalOfficeCities: PropTypes.object.isRequired,
  task: PropTypes.object.isRequired,
  pdfLink: PropTypes.string,
  pdfjsLink: PropTypes.string,
  handleAlert: PropTypes.func,
  handleAlertClear: PropTypes.func,
  specialIssues: PropTypes.object,
  establishClaimForm: PropTypes.object,
  onDuplicateEP: PropTypes.func,
  submitDecisionPage: PropTypes.func,
  submitDecisionPageSuccess: PropTypes.func,
  submitDecisionPageFailure: PropTypes.func,
  beginPerformEstablishClaim: PropTypes.func,
  performEstablishClaimSuccess: PropTypes.func,
  performEstablishClaimFailure: PropTypes.func,
  featureToggles: PropTypes.object
};

const mapStateToProps = (state) => ({
  specialIssues: state.specialIssues,
  establishClaimForm: state.establishClaimForm
});

const mapDispatchToProps = (dispatch) => ({
  // These would be better handled by refactoring API logic to a thunk
  submitDecisionPage: () =>
    dispatch({
      type: SUBMIT_DECISION_PAGE
    }),
  submitDecisionPageSuccess: () =>
    dispatch({
      type: SUBMIT_DECISION_PAGE_SUCCESS
    }),
  submitDecisionPageFailure: () =>
    dispatch({
      type: SUBMIT_DECISION_PAGE_FAILURE
    }),
  beginPerformEstablishClaim: () => {
    return dispatch({
      type: PERFORM_ESTABLISH_CLAIM_START
    });
  },
  performEstablishClaimSuccess: () => {
    return dispatch({
      type: PERFORM_ESTABLISH_CLAIM_SUCCESS
    });
  },
  performEstablishClaimFailure: () =>
    dispatch({
      type: PERFORM_ESTABLISH_CLAIM_FAILURE
    }),
  onDuplicateEP: (nextModifier) => {
    return dispatch({
      type: INCREMENT_MODIFIER_ON_DUPLICATE_EP_ERROR,
      payload: {
        value: nextModifier
      }
    });
  },
  dispatch
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(EstablishClaim);
