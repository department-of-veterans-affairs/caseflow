import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';
import _ from 'lodash';

import {
  setDecisionOptions,
  resetDecisionOptions,
  saveDecision
} from './QueueActions';
import {
  setSelectingJudge,
  pushBreadcrumb,
  highlightInvalidFormItems
} from './uiReducer/actions';

import decisionViewBase from './components/DecisionViewBase';
import RadioField from '../components/RadioField';
import Checkbox from '../components/Checkbox';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import Button from '../components/Button';
import Alert from '../components/Alert';

import {
  fullWidth,
  ERROR_FIELD_REQUIRED
} from './constants';
import SearchableDropdown from '../components/SearchableDropdown';

const smallBottomMargin = css({ marginBottom: '1rem' });
const noBottomMargin = css({ marginBottom: 0 });

const radioFieldStyling = css(noBottomMargin, {
  marginTop: '2rem',
  '& .question-label': {
    marginBottom: 0
  }
});
const subHeadStyling = css({ marginBottom: '2rem' });
const checkboxStyling = css({ marginTop: '1rem' });
const textAreaStyling = css({ marginTop: '4rem' });
const selectJudgeButtonStyling = (selectedJudge) => css({ paddingLeft: selectedJudge ? '' : 0 });

class SubmitDecisionView extends React.PureComponent {
  componentDidMount = () => {
    const { task: { attributes: task } } = this.props;

    this.props.setDecisionOptions({
      judge: {
        label: task.added_by_name,
        value: task.added_by_css_id
      }
    });
  };

  getBreadcrumb = () => ({
    breadcrumb: `Submit ${this.getDecisionTypeDisplay()}`,
    path: `/tasks/${this.props.vacolsId}/submit`
  });

  getDecisionTypeDisplay = () => {
    const {
      type: decisionType
    } = this.props.decision;

    return decisionType === 'omo' ? 'OMO' : StringUtil.titleCase(decisionType);
  };

  goToPrevStep = () => {
    this.props.resetDecisionOptions();

    return true;
  };

  validateForm = () => {
    const {
      type: decisionType,
      opts: decisionOpts
    } = this.props.decision;
    const requiredParams = ['documentId', 'judge'];

    if (decisionType.includes('OMO')) {
      requiredParams.push('omoType');
    }

    const missingParams = _.filter(requiredParams, (param) => !_.has(decisionOpts, param) || !decisionOpts[param]);

    return !missingParams.length;
  };

  goToNextStep = () => {
    const {
      vacolsId,
      decision: {
        type: decisionType,
        opts: decision
      }
    } = this.props;
    const params = {
      data: {
        queue: {
          work_product: decision.omoType, // todo: generify omoType field name
          reviewing_judge_id: decision.judge.value,
          document_id: decision.documentId,
          type: decisionType,
          overtime: decision.overtime || false,
          note: decision.notes
        }
      }
    }

    // todo: proceed on request resolve
    return this.props.saveDecision(vacolsId, params);
  }

  getFooterButtons = () => [{
    displayText: `< Go back to draft decision ${this.props.vbmsId}`
  }, {
    displayText: 'Submit'
  }];

  getJudgeSelectComponent = () => {
    const {
      selectingJudge,
      judges,
      decision: { opts: decisionOpts }
    } = this.props;

    if (selectingJudge) {
      return <React.Fragment>
        <SearchableDropdown
          name="Select a judge"
          placeholder="Select a judge&hellip;"
          options={_.map(judges, (judge, value) => ({
            label: judge.full_name,
            value
          }))}
          onChange={(judge) => {
            this.props.setSelectingJudge(false);
            this.props.setDecisionOptions({ judge });
          }}
          hideLabel />
      </React.Fragment>;
    }

    const selectedJudge = _.get(decisionOpts.judge, 'label');

    return <React.Fragment>
      {selectedJudge && <span>{selectedJudge}</span>}
      <Button
        id="select-judge"
        classNames={['cf-btn-link']}
        willNeverBeLoading
        styling={selectJudgeButtonStyling(selectedJudge)}
        onClick={() => this.props.setSelectingJudge(true)}>
        Select {selectedJudge ? 'another' : 'a'} judge
      </Button>
    </React.Fragment>;
  };

  render = () => {
    const omoTypes = [{
      displayText: 'VHA - OMO',
      value: 'OMO - VHA'
    }, {
      displayText: 'VHA - IME',
      value: 'OMO - IME'
    }];
    const {
      type: decisionType,
      opts: decisionOpts
    } = this.props.decision;
    const {
      highlightFormItems,
      error
    } = this.props;

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
        Submit {this.getDecisionTypeDisplay()} for Review
      </h1>
      <p className="cf-lead-paragraph" {...subHeadStyling}>
        Complete the details below to submit this {this.getDecisionTypeDisplay()} request for judge review.
      </p>
      {error.visible && <Alert title={error.message.title} type="error">
        {error.message.detail}
      </Alert>}
      <hr />
      {decisionType.includes('OMO') && <RadioField
        name="omo_type"
        label="OMO type:"
        onChange={(omoType) => this.props.setDecisionOptions({ omoType })}
        value={decisionOpts.omoType}
        vertical
        required
        options={omoTypes}
        styling={radioFieldStyling}
        errorMessage={(highlightFormItems && !decisionOpts.omoType) ? ERROR_FIELD_REQUIRED : ''}
      />}
      <Checkbox
        name="overtime"
        label="This work product is overtime"
        onChange={(overtime) => this.props.setDecisionOptions({ overtime })}
        value={decisionOpts.overtime || false}
        styling={css(smallBottomMargin, checkboxStyling)}
      />
      <TextField
        label="Document ID:"
        name="document_id"
        required
        errorMessage={(highlightFormItems && !decisionOpts.documentId) ? ERROR_FIELD_REQUIRED : ''}
        onChange={(documentId) => this.props.setDecisionOptions({ documentId })}
        value={decisionOpts.documentId}
      />
      <span>Submit to judge:</span><br />
      {this.getJudgeSelectComponent()}
      <TextareaField
        label="Notes:"
        name="notes"
        value={decisionOpts.notes}
        onChange={(notes) => this.props.setDecisionOptions({ notes })}
        styling={textAreaStyling}
      />
    </React.Fragment>;
  };
}

SubmitDecisionView.propTypes = {
  vacolsId: PropTypes.string.isRequired,
  vbmsId: PropTypes.string.isRequired,
  prevStep: PropTypes.string.isRequired,
  nextStep: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId],
  task: state.queue.loadedQueue.tasks[ownProps.vacolsId],
  decision: state.queue.pendingChanges.taskDecision,
  judges: state.queue.judges,
  error: state.ui.errorState.decision,
  ..._.pick(state.ui, 'highlightFormItems', 'selectingJudge')
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions,
  resetDecisionOptions,
  setSelectingJudge,
  pushBreadcrumb,
  highlightInvalidFormItems,
  saveDecision
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SubmitDecisionView));
