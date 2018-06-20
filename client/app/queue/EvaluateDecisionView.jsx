import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import moment from 'moment';
import StringUtil from '../util/StringUtil';
import scrollToComponent from 'react-scroll-to-component';

import decisionViewBase from './components/DecisionViewBase';
import RadioField from '../components/RadioField';
import CheckboxGroup from '../components/CheckboxGroup';
import TextareaField from '../components/TextareaField';
import CaseTitle from './CaseTitle';
import CaseSnapshot from './CaseSnapshot';
import Alert from '../components/Alert';

import { setDecisionOptions } from './QueueActions';

import COPY from '../../COPY.json';
import {
  marginBottom, marginTop,
  marginRight, paddingLeft,
  fullWidth, redText, PAGE_TITLES
} from './constants';
const setWidth = (width) => css({ width });
const headerStyling = marginBottom(1.5);
const inlineHeaderStyling = css(headerStyling, { float: 'left' });
const hrStyling = css(marginTop(2), marginBottom(3));
const qualityOfWorkAlertStyling = css({ borderLeft: '0.5rem solid #59BDE1' });
const errorStylingNoTopMargin = css({ '&.usa-input-error': marginTop(0) });

const twoColumnContainerStyling = css({
  display: 'inline-flex',
  width: '100%'
});
const leftColumnStyling = css({
  '@media(min-width: 950px)': setWidth('calc(50% - 2rem)'),
  '@media(max-width: 949px)': setWidth('calc(100% - 2rem)')
});
const subH2Styling = css(paddingLeft(1), { lineHeight: 2 });
const subH3Styling = css(paddingLeft(1), { lineHeight: 1.75 });

class EvaluateDecisionView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      caseComplexity: null,
      caseQuality: null,
      additionalFactors: '',
      areasOfImprovement: {}
    };
  }

  componentDidMount = () => this.setState(
    _.pick(this.props.taskOptions, _.keys(this.state))
  );

  getPageName = () => PAGE_TITLES.EVALUATE;

  getBreadcrumb = () => ({
    breadcrumb: this.getPageName(),
    path: `/queue/appeals/${this.props.appealId}/evaluate`
  });

  caseQualityIsDeficient = () => this.state.caseQuality > 0 && this.state.caseQuality < 3;

  // todo: consoldate w/IssueRemandReasonOptions.scrollTo
  // moving these into DecisionViewBase didn't work for some reason :\
  scrollTo = (dest = this, opts) => scrollToComponent(dest, _.defaults(opts, {
    align: 'top',
    duration: 1500,
    ease: 'outCube',
    offset: -10
  }));

  validateForm = () => {
    const {
      areasOfImprovement,
      caseComplexity,
      caseQuality
    } = this.state;

    if (!caseComplexity) {
      this.scrollTo(this.caseComplexityLabel);

      return false;
    }

    if (!caseQuality) {
      this.scrollTo(this.caseQualityLabel);

      return false;
    }

    if (this.caseQualityIsDeficient() && _.isEmpty(areasOfImprovement)) {
      this.scrollTo(this.deficientCaseQualityAlert);

      return false;
    }

    this.props.setDecisionOptions(this.state);

    return true;
  };

  getAreasOfImprovement = () => [
    COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_THEORY,
    COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_CASELAW,
    COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_STATUE,
    COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_ADMIN,
    COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_RELEVANT,
    COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_LAY,
    COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_IMPROPERLY_ADDRESSED,
    COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_FINDINGS_NOT_SUPPORTED,
    COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_DUE_PROCESS,
    COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_INCOMPLETE_REMANDS,
    COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_ERRORS
  ].map((opt) => ({
    id: StringUtil.parameterize(opt),
    label: opt
  }));

  setAreasOfImprovement = (event) => {
    const factor = event.target.name;
    const newOpts = this.state.areasOfImprovement;

    if (factor in this.state.areasOfImprovement) {
      delete newOpts[factor];
    } else {
      newOpts[factor] = true;
    }

    this.setState({ areasOfImprovement: newOpts });
  }

  render = () => {
    const {
      appeal: { attributes: appeal },
      task: { attributes: task },
      appealId,
      highlight
    } = this.props;
    const dateAssigned = moment(task.assigned_on);
    const decisionSubmitted = moment(task.previous_task.assigned_on);
    const daysWorked = moment().startOf('day').
      diff(dateAssigned, 'days');

    return <React.Fragment>
      <CaseTitle
        heading={appeal.veteran_full_name}
        vacolsId={appealId}
        appeal={this.props.appeal}
        analyticsSource="evaluate_decision"
        taskType="Dispatch"
        redirectUrl={window.location.pathname} />
      <h1 {...css(fullWidth, marginBottom(2), marginTop(2))}>
        {this.getPageName()}
      </h1>
      <CaseSnapshot appeal={this.props.appeal} task={this.props.task} />
      <hr {...hrStyling} />

      <h2 {...headerStyling}>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_LABEL}</h2>
      <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE}</b>: {dateAssigned.format('M/D/YY')}<br />
      <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBMITTED_DATE}</b>: {decisionSubmitted.format('M/D/YY')}<br />
      <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED}</b>&nbsp;
      ({COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED_ADDENDUM}): {daysWorked}<br />

      <hr {...hrStyling} />

      <h2 {...headerStyling} ref={(node) => this.caseComplexityLabel = node}>
        {COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_LABEL}
      </h2>
      <h3>{COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_SUBHEAD}</h3>
      <RadioField vertical hideLabel
        name={COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_LABEL}
        onChange={(caseComplexity) => this.setState({ caseComplexity })}
        value={this.state.caseComplexity}
        styling={css(marginBottom(0), errorStylingNoTopMargin)}
        errorMessage={highlight && !this.state.caseComplexity ? 'Choose one' : null}
        options={[{
          value: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_EASY.toLowerCase(),
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_EASY
        }, {
          value: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_MEDIUM.toLowerCase(),
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_MEDIUM
        }, {
          value: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_HARD.toLowerCase(),
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_HARD
        }]} />

      <hr {...hrStyling} />

      <h2 {...headerStyling} ref={(node) => this.caseQualityLabel = node}>
        {COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_LABEL}
      </h2>
      <h3>{COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_SUBHEAD}</h3>
      <RadioField vertical hideLabel
        name={COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_LABEL}
        onChange={(caseQuality) => this.setState({ caseQuality })}
        value={this.state.caseQuality}
        styling={css(marginBottom(0), errorStylingNoTopMargin)}
        errorMessage={highlight && !this.state.caseQuality ? 'Choose one' : null}
        options={[{
          value: '5',
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_5
        }, {
          value: '4',
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_4
        }, {
          value: '3',
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_3
        }, {
          value: '2',
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_2
        }, {
          value: '1',
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_1
        }]} />

      {this.caseQualityIsDeficient() && <Alert ref={(node) => this.deficientCaseQualityAlert = node}
        type="info"
        scrollOnAlert={false}
        styling={qualityOfWorkAlertStyling}>
        Please provide more details about <b>quality of work</b>. If none of these apply to
        this case, please share <b>additional comments</b> below.
      </Alert>}

      <div {...css(setWidth('100%'), marginTop(4))}>
        <h3 {...css(headerStyling, { float: this.caseQualityIsDeficient() ? 'left' : '' })}>
          {COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
        </h3>
        {this.caseQualityIsDeficient() && <span {...css(subH3Styling, redText)}>Choose at least one</span>}
      </div>
      <div {...twoColumnContainerStyling}>
        <div className="cf-push-left" {...css(marginRight(2), leftColumnStyling)}>
          <CheckboxGroup
            hideLabel vertical
            name={COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
            onChange={this.setAreasOfImprovement}
            errorState={highlight && this.caseQualityIsDeficient() && _.isEmpty(this.state.areasOfImprovement)}
            value={this.state.areasOfImprovement}
            options={this.getAreasOfImprovement().slice(0, 6)} />
        </div>
        <div className="cf-push-left">
          <CheckboxGroup
            hideLabel vertical
            name={COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
            onChange={this.setAreasOfImprovement}
            value={this.state.areasOfImprovement}
            options={this.getAreasOfImprovement().slice(6)} />
        </div>
      </div>

      <hr {...hrStyling} />

      <h2 {...inlineHeaderStyling}>{COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_LABEL}</h2>
      <span {...subH2Styling}>Optional</span>
      <h3>{COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_SUBHEAD}</h3>
      <TextareaField
        name="additional-factors"
        label={COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_SUBHEAD}
        hideLabel
        value={this.state.additionalFactors}
        onChange={(additionalFactors) => this.setState({ additionalFactors })} />
    </React.Fragment>;
  };
}

EvaluateDecisionView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.appealId],
  task: state.queue.loadedQueue.tasks[ownProps.appealId],
  highlight: state.ui.highlightFormItems,
  taskOptions: state.queue.stagedChanges.taskDecision.opts
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(EvaluateDecisionView));
