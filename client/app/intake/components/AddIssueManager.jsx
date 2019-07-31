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
              notes }, () => {
              if (isCorrection(currentIssue.isRating, this.props.intakeData)) {
                this.setState({ currentModal: 'CorrectionTypeModal' });
              } else if (this.hasLegacyAppeals()) {
                this.setState({ currentModal: 'LegacyOptInModal' });
              } else if (this.requiresUntimelyExemption()) {
                this.setState({ currentModal: 'UntimelyExemptionModal',
                  addtlProps: { currentIssue } });
              } else {
                // Dispatch action to add issue
                this.props.addIssue(currentIssue);

                this.setState(initialState);
                this.props.onComplete();
              }
            });
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
          submitText: this.hasLegacyAppeals() || this.requiresUntimelyExemption() ? 'Next' : 'Add this issue',
          onCancel: () => this.cancel(),
          onSubmit: ({ correctionType }) => {
            // update data
            this.setState({ correctionType });

            if (this.hasLegacyAppeals()) {
              this.setState({ currentModal: 'LegacyOptInModal' });
            } else if (this.requiresUntimelyExemption()) {
              const { currentIssue } = this.state;

              this.setState({ currentModal: 'UntimelyExemptionModal',
                addtlProps: { currentIssue } });
            } else {
              const { currentIssue } = this.state;

              // Sequence complete — dispatch action to add issue
              this.props.addIssue(currentIssue);

              this.props.onComplete();
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
              if (isCorrection(currentIssue.isRating, this.props.intakeData)) {
                this.setState({ currentModal: 'CorrectionTypeModal' });
              } else if (this.hasLegacyAppeals()) {
                this.setState({ currentModal: 'LegacyOptInModal' });
              } else if (currentIssue.timely === false) {
                this.setState({ currentModal: 'UntimelyExemptionModal',
                  addtlProps: { currentIssue } });
              } else {
                this.props.addIssue(currentIssue);
                this.props.onComplete();
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
            this.setState(
              {
                currentIssue: {
                  ...this.state.currentIssue,
                  vacolsId,
                  vacolsSequenceId,
                  eligibleForSocOptIn
                }
              },
              () => {
                const { currentIssue } = this.state;

                if (this.requiresUntimelyExemption()) {
                  this.setState({ currentModal: 'UntimelyExemptionModal',
                    addtlProps: { currentIssue } });
                } else if (this.state.currentIssue.category) {
                  console.log('addNonratingRequestIssue');
                  // addNonratingRequestIssue
                  // Sequence complete — dispatch action to add issue
                  this.props.addIssue(currentIssue);
                } else {
                  console.log('addContestableIssue');
                  // addContestableIssue
                  // const { currentIssue, notes, correctionType } = this.state;

                  // this.props.addContestableIssue({
                  //   contestableIssueIndex: currentIssue.index,
                  //   contestableIssues: intakeData.contestableIssues,
                  //   isRating: currentIssue.isRating,
                  //   vacolsId,
                  //   vacolsSequenceId,
                  //   eligibleForSocOptIn,
                  //   notes,
                  //   correctionType
                  // });

                  this.props.addIssue(currentIssue);

                  this.setState(initialState);
                  this.props.onComplete();
                }
              }
            );
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
            this.setState(
              {
                currentIssue: {
                  ...this.state.currentIssue,
                  untimelyExemption,
                  untimelyExemptionNotes
                }
              },
              () => {
                const {
                  currentIssue
                  // notes,
                  // vacolsId,
                  // vacolsSequenceId,
                  // eligibleForSocOptIn,
                  // correctionType
                } = this.state;

                this.props.addIssue(currentIssue);

                // if (currentIssue.category) {
                //   this.props.addNonratingRequestIssue({
                //     timely: false,
                //     isRating: false,
                //     untimelyExemption,
                //     untimelyExemptionNotes,
                //     benefitType: currentIssue.benefitType,
                //     category: currentIssue.category,
                //     description: currentIssue.description,
                //     decisionDate: currentIssue.decisionDate,
                //     vacolsId,
                //     vacolsSequenceId,
                //     eligibleForSocOptIn,
                //     correctionType
                //   });
                // } else {
                //   this.props.addContestableIssue({
                //     timely: false,
                //     contestableIssueIndex: currentIssue.index,
                //     contestableIssues: this.props.intakeData.contestableIssues,
                //     isRating: currentIssue.isRating,
                //     notes,
                //     untimelyExemption,
                //     untimelyExemptionNotes,
                //     vacolsId,
                //     vacolsSequenceId,
                //     eligibleForSocOptIn,
                //     correctionType
                //   });
                // }

                this.setState(initialState);
              }
            );
          }
        }
      },
      UnidentifiedIssuesModal: {
        component: UnidentifiedIssuesModal,
        props: {
          intakeData,
          formType,
          onCancel: () => this.cancel(),
          onSubmit: ({ currentIssue }) => {
            if (isCorrection(currentIssue.isRating, this.props.intakeData)) {
              this.setState({ currentModal: 'CorrectionTypeModal' });
            } else {
              // Just add
              this.props.addIssue(currentIssue);
            }
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
        addContestableIssue,
        addIssue
      },
      dispatch
    )
)(AddIssueManager);
