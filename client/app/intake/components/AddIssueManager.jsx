import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AddIssuesModal from './AddIssuesModal';
import CorrectionTypeModal from './CorrectionTypeModal';
import NonratingRequestIssueModal from './NonratingRequestIssueModal';
import { isCorrection } from '../util';
import LegacyOptInModal from './LegacyOptInModal';
import UntimelyExemptionModal from './UntimelyExemptionModal';
import { addContestableIssue, addIssue } from '../actions/addIssues';
import UnidentifiedIssuesModal from './UnidentifiedIssuesModal';

const initialState = {
  currentModal: 'AddIssuesModal',
  currentIssue: null,
  correctionType: null,
  addtlProps: null
};

class AddIssueManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...initialState,
      currentModal: this.props.currentModal || initialState.currentModal
    };

    // Determine initial step -- though we still honor prop, if exists
    const { intakeData } = this.props;
    const hasContestableIssues = Boolean(Object.keys(intakeData.contestableIssues).length);

    if (!this.props.currentModal && !hasContestableIssues) {
      this.state.currentModal = 'NonratingRequestIssueModal';
    }

    this.setupSteps();
  }

  cancel() {
    this.setState(initialState);
    this.props.onComplete();
  }

  setupAddIssuesModal = () => {
    const { intakeData, formType } = this.props;

    return {
      component: AddIssuesModal,
      props: {
        intakeData,
        formType,
        onCancel: () => this.cancel(),
        onSubmit: ({ selectedContestableIssueIndex, currentIssue, notes }) => {
          this.setState(
            {
              selectedContestableIssueIndex,
              currentIssue,
              notes
            },
            () => {
              if (isCorrection(currentIssue.isRating, this.props.intakeData)) {
                this.setState({ currentModal: 'CorrectionTypeModal' });
              } else if (this.hasLegacyAppeals()) {
                this.setState({ currentModal: 'LegacyOptInModal', addtlProps: { currentIssue } });
              } else if (this.requiresUntimelyExemption()) {
                this.setState({ currentModal: 'UntimelyExemptionModal', addtlProps: { currentIssue } });
              } else {
                // Dispatch action to add issue
                this.props.addIssue(currentIssue);

                this.setState(initialState);
                this.props.onComplete();
              }
            }
          );
        },
        onSkip: () => {
          this.setState({ currentModal: 'NonratingRequestIssueModal' });
        }
      }
    };
  };

  setupCorrectionTypeModal = () => {
    return {
      component: CorrectionTypeModal,
      props: {
        cancelText: 'Cancel adding this issue',
        submitText: this.hasLegacyAppeals() || this.requiresUntimelyExemption() ? 'Next' : 'Add this issue',
        onCancel: () => this.cancel(),
        onSubmit: ({ correctionType }) => {
          // update data
          this.setState(
            {
              currentIssue: {
                ...this.state.currentIssue,
                correctionType
              }
            },
            () => {
              const { currentIssue } = this.state;

              if (this.hasLegacyAppeals()) {
                this.setState({ currentModal: 'LegacyOptInModal', addtlProps: { currentIssue } });
              } else if (this.requiresUntimelyExemption()) {
                this.setState({ currentModal: 'UntimelyExemptionModal', addtlProps: { currentIssue } });
              } else {
                // Sequence complete — dispatch action to add issue
                this.props.addIssue(currentIssue);

                this.props.onComplete();
              }
            }
          );
        }
      }
    };
  };

  setupNonratingRequestIssueModal = () => {
    const { intakeData, formType, featureToggles } = this.props;

    return {
      component: NonratingRequestIssueModal,
      props: {
        intakeData,
        formType,
        featureToggles,
        submitText: this.hasLegacyAppeals() ? 'Next' : 'Add this issue',
        onCancel: () => this.cancel(),
        onSkip: () => this.setState({ currentModal: 'UnidentifiedIssuesModal' }),
        onSubmit: ({ currentIssue }) => {
          this.setState({ currentIssue }, () => {
            if (isCorrection(currentIssue.isRating, this.props.intakeData)) {
              this.setState({ currentModal: 'CorrectionTypeModal' });
            } else if (this.hasLegacyAppeals()) {
              this.setState({ currentModal: 'LegacyOptInModal', addtlProps: { currentIssue } });
            } else if (currentIssue.timely === false) {
              this.setState({ currentModal: 'UntimelyExemptionModal', addtlProps: { currentIssue } });
            } else {
              this.props.addIssue(currentIssue);
              this.props.onComplete();
            }
          });
        }
      }
    };
  };

  setupLegacyOptInModal = () => {
    const { intakeData, formType } = this.props;

    return {
      component: LegacyOptInModal,
      props: {
        intakeData,
        formType,
        submitText: this.requiresTimelyRules() ? 'Next' : 'Add this issue',
        onCancel: () => this.cancel(),
        onSubmit: ({ vacolsId, vacolsSequenceId, eligibleForSocOptIn, eligibleForSocOptInWithExemption }) => {
          this.setState(
            {
              currentIssue: {
                ...this.state.currentIssue,
                vacolsId,
                vacolsSequenceId,
                eligibleForSocOptIn,
                eligibleForSocOptInWithExemption
              }
            },
            () => {
              const { currentIssue } = this.state;

              if (this.requiresTimelyRules()) {
                this.setState({ currentModal: 'UntimelyExemptionModal', addtlProps: { currentIssue } });
              } else {
                this.props.addIssue(currentIssue);

                this.setState(initialState);
                this.props.onComplete();
              }
            }
          );
        }
      }
    };
  };

  setupUntimelyExemptionModal = () => {
    const { intakeData, formType } = this.props;

    return {
      component: UntimelyExemptionModal,
      props: {
        intakeData,
        formType,
        onCancel: () => this.cancel(),
        onSubmit: ({ untimelyExemption, untimelyExemptionNotes, untimelyExemptionCovid }) => {
          this.setState(
            {
              currentIssue: {
                ...this.state.currentIssue,
                untimelyExemption,
                untimelyExemptionNotes,
                untimelyExemptionCovid
              }
            },
            () => {
              const { currentIssue } = this.state;

              this.props.addIssue(currentIssue);

              this.setState(initialState);
              this.props.onComplete();
            }
          );
        }
      }
    };
  };

  setupUnidentifiedIssuesModal = () => {
    const { intakeData, formType, featureToggles, editPage } = this.props;

    return {
      component: UnidentifiedIssuesModal,
      props: {
        intakeData,
        formType,
        featureToggles,
        editPage,
        submitText: 'Add this issue',
        onCancel: () => this.cancel(),
        onSubmit: ({ currentIssue }) => {
          if (isCorrection(true, this.props.intakeData)) {
            this.setState({ currentIssue, currentModal: 'CorrectionTypeModal' });
          } else if (currentIssue.timely === false) {
            this.setState({ currentIssue, currentModal: 'UntimelyExemptionModal', addtlProps: { currentIssue } });
          } else {
            // Just add
            this.props.addIssue(currentIssue);
            this.props.onComplete();
          }
        }
      }
    };
  };

  setupSteps() {
    this.steps = {
      AddIssuesModal: this.setupAddIssuesModal(),
      CorrectionTypeModal: this.setupCorrectionTypeModal(),
      NonratingRequestIssueModal: this.setupNonratingRequestIssueModal(),
      LegacyOptInModal: this.setupLegacyOptInModal(),
      UntimelyExemptionModal: this.setupUntimelyExemptionModal(),
      UnidentifiedIssuesModal: this.setupUnidentifiedIssuesModal()
    };
  }

  hasLegacyAppeals = () => {
    return this.props.intakeData.legacyAppeals.length > 0;
  };

  requiresUntimelyExemption = () => {
    if (this.props.formType === 'supplemental_claim') {
      return false;
    }
    const { currentIssue } = this.state;

    // Skip untimely check for legacy issues
    if (currentIssue?.vacolsId) {
      return false;
    }

    // Skip untimely check for unidentified issues
    if (currentIssue?.isUnidentified) {
      return false;
    }

    return currentIssue && !currentIssue.timely;
  };

  requiresUntimelyExemptionWithCovid = () => {
    const { currentIssue } = this.state;
    const { formType } = this.props;
    const vacolsIdCheck = currentIssue?.vacolsId;
    const legacyIssueIsTimely = !vacolsIdCheck || !this.props.intakeData.legacyOptInApproved ||
      currentIssue?.eligibleForSocOptIn || !currentIssue?.eligibleForSocOptInWithExemption;
    const requestIssueIsTimely = currentIssue?.timely;

    if (formType === 'appeal') {
      return !requestIssueIsTimely && !vacolsIdCheck;
    }

    if (formType === 'supplemental_claim') {
      return !legacyIssueIsTimely;
    }

    if (formType === 'higher_level_review') {
      if (requestIssueIsTimely) {
        return !legacyIssueIsTimely;
      }

      return true;
    }
  };

  requiresTimelyRules = () => {
    const { covidTimelinessExemption } = this.props.featureToggles;

    if (covidTimelinessExemption) {
      return this.requiresUntimelyExemptionWithCovid();
    }

    return this.requiresUntimelyExemption();

  }

  render() {
    const { currentModal, addtlProps } = this.state;

    if (!currentModal) {
      return null;
    }

    const step = this.steps[currentModal];
    const Step = step.component;

    return <Step onComplete={step.onComplete} {...step.props} {...addtlProps} />;
  }
}

AddIssueManager.propTypes = {
  currentModal: PropTypes.string,
  onComplete: PropTypes.func,
  featureToggles: PropTypes.object,
  intakeData: PropTypes.object,
  formType: PropTypes.string,
  addIssue: PropTypes.func,
  editPage: PropTypes.bool
};

AddIssueManager.defaultProps = {
  // currentModal: 'AddIssuesModal',
  onComplete: () => {
    return null;
  }
};

export default connect(
  null,
  (dispatch) =>
    bindActionCreators(
      {
        addContestableIssue,
        addIssue
      },
      dispatch
    )
)(AddIssueManager);
