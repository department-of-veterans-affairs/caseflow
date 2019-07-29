import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AddIssuesModal from './AddIssuesModal';
import CorrectionTypeModal from './CorrectionTypeModal';
import NonratingRequestIssueModal from './NonratingRequestIssueModal';
import { issueByIndex } from '../util/issues';
import { isCorrection } from '../util';
import LegacyOptInModal from './LegacyOptInModal';
import UntimelyExemptionModal from './UntimelyExemptionModal';
import { addContestableIssue } from '../actions/addIssues';
import UnidentifiedIssuesModal from './UnidentifiedIssuesModal';

const initialState = {
  currentModal: 'AddIssuesModal',
  currentIssue: null,
  correctionType: null
};

class AddIssueManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = initialState;

    this.setupSteps();
  }

  cancel() {
    this.setState(initialState);
    this.props.onComplete();
  }

  setupSteps() {
    const { intakeData, formType } = this.props;

    this.steps = {
      AddIssuesModal: {
        component: AddIssuesModal,
        props: {
          intakeData,
          formType,
          onCancel: () => this.cancel(),
          onSubmit: ({ selectedContestableIssueIndex, currentIssue, notes }) => {
            this.setState({ selectedContestableIssueIndex,
              currentIssue,
              notes });

            if (isCorrection(currentIssue.isRating, this.props.intakeData)) {
              this.setState({ currentModal: 'CorrectionTypeModal' });
            }
          },
          onSkip: () => {
            this.setState({ currentModal: 'NonratingRequestIssueModal' });
          }
        }
      },
      CorrectionTypeModal: {
        component: CorrectionTypeModal,
        props: {
          cancelText: 'Cancel adding this issue',
          submitText: 'Next',
          onCancel: () => this.cancel(),
          onSubmit: ({ correctionType }) => {
            // update data
            this.setState({ correctionType });

            if (this.hasLegacyAppeals()) {
              this.setState({ currentModal: 'LegacyOptInModal' });
            } else if (this.requiresUntimelyExemption()) {
              this.setState({ currentModal: 'UntimelyExemptionModal' });
            } else {
              // create
            }
          }
        }
      },
      NonratingRequestIssueModal: {
        component: NonratingRequestIssueModal,
        props: {
          intakeData,
          formType,
          submitText: this.hasLegacyAppeals() ? 'Next' : 'Add this issue',
          onCancel: () => this.cancel(),
          onSkip: () => this.setState({ component: 'UnidentifiedIssuesModal' }),
          onSubmit: ({ currentIssue }) => {
            this.setState({ currentIssue }, () => {
              if (this.hasLegacyAppeals()) {
                this.setState({ component: 'LegacyOptInModal' });
              } else if (currentIssue.timely === false) {
                this.setState({ component: 'UntimelyExemptionModal' });
              } else {
                this.setState({ currentModal: 'CorrectionTypeModal' });
              }
            });
          }
        }
      },
      LegacyOptInModal: {
        component: LegacyOptInModal,
        props: {
          intakeData,
          formType,
          submitText: this.requiresUntimelyExemption() ? 'Next' : 'Add this issue',
          onCancel: () => this.cancel(),
          onSubmit: ({ vacolsId, vacolsSequenceId, eligibleForSocOptIn }) => {
            this.setState({ vacolsId,
              vacolsSequenceId,
              eligibleForSocOptIn }, () => {
              if (this.requiresUntimelyExemption()) {
                this.setState({ currentModal: 'UntimelyExemptionModal' });
              } else if (this.state.currentIssue.category) {
                console.log('addNonratingRequestIssue');
                // addNonratingRequestIssue
              } else {
                console.log('addContestableIssue');
                // addContestableIssue
                const { currentIssue, notes, correctionType } = this.state;

                this.props.addContestableIssue({
                  contestableIssueIndex: currentIssue.index,
                  contestableIssues: intakeData.contestableIssues,
                  isRating: currentIssue.isRating,
                  vacolsId,
                  vacolsSequenceId,
                  eligibleForSocOptIn,
                  notes,
                  correctionType
                });

                // In case we aren't destroying component upon completion
                this.setState(initialState);
                this.props.onComplete();
              }
            });
          }
        }
      },
      UntimelyExemptionModal: {
        component: UntimelyExemptionModal,
        props: {
          intakeData,
          formType,
          onCancel: () => this.cancel(),
          onSubmit: ({ untimelyExemption, untimelyExemptionNotes }) => {
            this.setState({ untimelyExemption,
              untimelyExemptionNotes }, () => {
              const {
                currentIssue,
                notes,
                vacolsId,
                vacolsSequenceId,
                eligibleForSocOptIn,
                correctionType
              } = this.state;

              if (currentIssue.category) {
                this.props.addNonratingRequestIssue({
                  timely: false,
                  isRating: false,
                  untimelyExemption,
                  untimelyExemptionNotes,
                  benefitType: currentIssue.benefitType,
                  category: currentIssue.category,
                  description: currentIssue.description,
                  decisionDate: currentIssue.decisionDate,
                  vacolsId,
                  vacolsSequenceId,
                  eligibleForSocOptIn,
                  correctionType
                });
              } else {
                this.props.addContestableIssue({
                  timely: false,
                  contestableIssueIndex: currentIssue.index,
                  contestableIssues: this.props.intakeData.contestableIssues,
                  isRating: currentIssue.isRating,
                  notes,
                  untimelyExemption,
                  untimelyExemptionNotes,
                  vacolsId,
                  vacolsSequenceId,
                  eligibleForSocOptIn,
                  correctionType
                });
              }
            });
          }
        }
      }
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

    return currentIssue && !currentIssue.timely;
  };

  render() {
    if (!this.state.currentModal) {
      return null;
    }

    const step = this.steps[this.state.currentModal];
    const Step = step.component;

    return <Step onComplete={step.onComplete} {...step.props} />;
  }
}

AddIssueManager.propTypes = {
  onComplete: PropTypes.func
};

AddIssueManager.defaultProps = {
  onComplete: () => {}
};

export default connect(
  null,
  (dispatch) =>
    bindActionCreators(
      {
        addContestableIssue
      },
      dispatch
    )
)(AddIssueManager);
