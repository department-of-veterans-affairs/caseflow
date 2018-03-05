import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';
import _ from 'lodash';

import {
  setDecisionOptions,
  setSelectingJudge,
  pushBreadcrumb,
  highlightMissingFormItems
} from './QueueActions';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import RadioField from '../components/RadioField';
import Checkbox from '../components/Checkbox';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import Button from '../components/Button';
import DecisionViewFooter from './components/DecisionViewFooter';

import { fullWidth } from './constants';
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
    const {
      vacolsId,
      task: { attributes: task }
    } = this.props;

    this.props.highlightMissingFormItems(false);
    this.props.pushBreadcrumb({
      breadcrumb: `Submit ${this.getDecisionTypeDisplay()}`,
      path: `/tasks/${vacolsId}/submit`
    });
    this.props.setDecisionOptions({
      judge: {
        label: task.added_by_name,
        value: task.added_by_css_id
      }
    });
  }

  getDecisionTypeDisplay = () => {
    const {
      type: decisionType
    } = this.props.decision;

    return decisionType === 'omo' ? 'OMO' : StringUtil.titleCase(decisionType);
  }

  getFooterButtons = () => [{
    displayText: `Go back to draft decision ${this.props.vbmsId}`,
    classNames: ['cf-btn-link'],
    callback: this.props.goToPrevStep
  }, {
    displayText: 'Submit',
    classNames: ['cf-right-side'],
    callback: () => {
      const {
        type: decisionType,
        opts: decisionOpts
      } = this.props.decision;
      const requiredParams = ['documentId', 'judge'];

      if (decisionType === 'omo') {
        requiredParams.push('omoType');
      }

      const missingParams = _.filter(requiredParams, (param) => !_.has(decisionOpts, param));

      if (missingParams.length === 0) {
        this.props.goToNextStep();
      } else {
        this.props.highlightMissingFormItems(true);
      }
    }
  }]

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
          options={_.map(judges, (judge) => ({
            label: judge.full_name,
            value: judge.css_id
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
  }

  render = () => {
    const omoTypes = [{
      displayText: 'VHA - OMO',
      value: 'omo'
    }, {
      displayText: 'VHA - IME',
      value: 'ime'
    }];
    const {
      type: decisionType,
      opts: decisionOpts
    } = this.props.decision;
    const { highlightFormItems } = this.props;

    return <React.Fragment>
      <AppSegment filledBackground>
        <h1 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
          Submit {this.getDecisionTypeDisplay()} for Review
        </h1>
        <p className="cf-lead-paragraph" {...subHeadStyling}>
          Complete the details below to submit this {this.getDecisionTypeDisplay()} request for judge review.
        </p>
        <hr />
        {decisionType === 'omo' && <RadioField
          name="omo_type"
          label="OMO type:"
          onChange={(omoType) => this.props.setDecisionOptions({ omoType })}
          value={decisionOpts.omoType}
          vertical
          required
          options={omoTypes}
          styling={radioFieldStyling}
          errorMessage={(highlightFormItems && !decisionOpts.omoType) ? 'This field is required' : ''}
        />}
        <Checkbox
          name="overtime"
          label="This work product is overtime"
          onChange={(overtime) => this.props.setDecisionOptions({ overtime })}
          value={decisionOpts.overtime}
          styling={css(smallBottomMargin, checkboxStyling)}
        />
        <TextField
          label="Document ID:"
          name="document_id"
          required
          errorMessage={(highlightFormItems && !decisionOpts.documentId) ? 'This field is required' : ''}
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
      </AppSegment>
      <DecisionViewFooter buttons={this.getFooterButtons()} />
    </React.Fragment>;
  };
}

SubmitDecisionView.propTypes = {
  vacolsId: PropTypes.string.isRequired,
  vbmsId: PropTypes.string.isRequired,
  goToNextStep: PropTypes.func.isRequired,
  goToPrevStep: PropTypes.func.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId],
  task: state.queue.loadedQueue.tasks[ownProps.vacolsId],
  decision: state.queue.taskDecision,
  judges: state.queue.judges,
  ..._.pick(state.queue.ui, 'highlightFormItems', 'selectingJudge')
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions,
  setSelectingJudge,
  pushBreadcrumb,
  highlightMissingFormItems
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SubmitDecisionView);
