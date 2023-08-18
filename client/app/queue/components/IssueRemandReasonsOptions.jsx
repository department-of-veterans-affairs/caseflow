import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import {
  compact,
  defaults,
  every,
  flatten,
  fromPairs,
  isNull,
  last,
  zip,
  map,
  filter,
  each,
  find,
  values
} from 'lodash';
import { css } from 'glamor';
import { formatDateStr } from '../../util/DateUtil';
import scrollToComponent from 'react-scroll-to-component';

import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import COPY from '../../../COPY';
import Checkbox from '../../components/Checkbox';
import CheckboxGroup from '../../components/CheckboxGroup';
import RadioField from '../../components/RadioField';

import { getIssueProgramDescription, getIssueTypeDescription, getIssueDiagnosticCodeLabel } from '../utils';
import {
  fullWidth,
  REMAND_REASONS,
  LEGACY_REMAND_REASONS,
  VACOLS_DISPOSITIONS,
  ISSUE_DISPOSITIONS,
  redText,
  boldText
} from '../constants';

const smallLeftMargin = css({ marginLeft: '1rem' });
const smallBottomMargin = css({ marginBottom: '1rem' });
const errorNoTopMargin = css({
  '.usa-input-error': { marginTop: 0 }
});
const flexContainer = css({
  display: 'flex',
  maxWidth: '75rem'
});
const flexColumn = css({
  flexDirection: 'row',
  flexWrap: 'wrap',
  width: '50%'
});

class IssueRemandReasonsOptions extends React.PureComponent {
  elTopOfWarning;

  constructor(props) {
    super(props);

    const { appeal } = this.props;

    const options = flatten(values(appeal.isLegacyAppeal ? LEGACY_REMAND_REASONS : REMAND_REASONS));
    const pairs = zip(
      map(options, 'id'),
      map(options, () => ({
        checked: false,
        post_aoj: null
      }))
    );

    this.state = fromPairs(pairs);
  }

  updateIssue = (remandReasons) => {
    const { appeal, issueId } = this.props;
    const issues = appeal.isLegacyAppeal ? appeal.issues : appeal.decisionIssues;

    return {
      ...find(issues, (issue) => issue.id === issueId),
      remand_reasons: remandReasons
    };
  };

  getChosenOptions = () => filter(this.state, (val) => val.checked);

  validate = () => {
    const chosenOptions = this.getChosenOptions();

    return chosenOptions.length >= 1 && every(chosenOptions, (opt) => !isNull(opt.post_aoj));
  };

  // todo: make scrollTo util function that also sets focus
  // element focus info https://goo.gl/jCkoxP
  scrollTo = (dest = this, opts) =>
    scrollToComponent(
      dest,
      defaults(opts, {
        align: 'top',
        duration: 1500,
        ease: 'outCube',
        offset: -35
      })
    );

  componentDidMount = () => {
    const {
      issue: { id: issueId, remand_reasons: remandReasons },
      issues
    } = this.props;

    each(remandReasons, (reason) =>
      this.setState({
        [reason.code]: {
          checked: true,
          post_aoj: reason.post_aoj.toString()
        }
      })
    );

    if (map(issues, 'id').indexOf(issueId) > 0) {
      this.scrollTo();
    }
  };

  updateStoreIssue = () => {
    // on going to the next or previous page, update issue attrs from state
    // "remand_reasons": [
    //   {"code": "AB", "post_aoj": true},
    //   {"code": "AC", "post_aoj": false}
    // ]
    const remandReasons = compact(map(this.state, (val, key) => {
      if (!val.checked) {
        return false;
      }

      return {
        code: key,
        post_aoj: val.post_aoj === 'true'
      };
    }));

    return this.updateIssue(remandReasons);
  };

  scrollToWarning = () => {
    // If the user gets the 'Choose at least one' error, scroll up so they can see it.
    // If the warning element isn't in the DOM when this is triggered (the first time),
    // it won't scroll to the correct position: scroll to where the element will be.
    this.scrollTo(this.elTopOfWarning, {
      offset: 25,
      duration: 1000
    });
  };

  toggleRemandReason = (checked, event) => {
    const splitId = event.target.id.split('-');

    this.setState({
      [splitId[splitId.length - 1]]: {
        checked,
        post_aoj: null
      }
    });
  };

  // Allow only certain AMA remand reasons to show pre/post AOJ subselections
  showAMASubSelections = (checkboxValue, legacyAppeal) => {
    return legacyAppeal ? true : checkboxValue.includes(REMAND_REASONS.other[1].id);
  };

  getCheckbox = (option, onChange, checkboxValues) => {
    const rowOptId = `${String(this.props.issue.id)}-${option.id}`;
    const { appeal } = this.props;
    const copyPrefix = appeal.isLegacyAppeal ? 'LEGACY' : 'AMA';

    return (
      <React.Fragment key={option.id}>
        <Checkbox
          name={rowOptId}
          onChange={onChange}
          value={checkboxValues[option.id].checked}
          label={option.label}
          unpadded
        />
        {checkboxValues[option.id].checked && this.showAMASubSelections(rowOptId, appeal.isLegacyAppeal) && (
          <RadioField
            errorMessage={
              this.props.highlight &&
              isNull(this.state[option.id].post_aoj) &&
              'Choose one'
            }
            styling={css(smallLeftMargin, smallBottomMargin, errorNoTopMargin)}
            name={rowOptId}
            vertical
            hideLabel
            options={[
              {
                displayText:
                  COPY[`${copyPrefix}_REMAND_REASON_POST_AOJ_LABEL_BEFORE`],
                value: 'false',
              },
              {
                displayText:
                  COPY[`${copyPrefix}_REMAND_REASON_POST_AOJ_LABEL_AFTER`],
                value: 'true',
              },
            ]}
            value={this.state[option.id].post_aoj}
            onChange={(postAoj) =>
              this.setState({
                [option.id]: {
                  checked: true,
                  post_aoj: postAoj,
                },
              })
            }
          />
        )}
      </React.Fragment>
    );
  };

  //  Selects the section and index of Remand Reason from Legacy Active Remand Reasons JSON list,
  //  and filters it out of selectable checkboxes.
  filterSelectableLegacyRemandReasons = (sectionName, index) => {
    delete LEGACY_REMAND_REASONS[sectionName][index];

  };

  getCheckboxGroup = () => {
    const { appeal } = this.props;
    const checkboxGroupProps = {
      onChange: this.toggleRemandReason,
      getCheckbox: this.getCheckbox,
      values: this.state
    };

    if (appeal.isLegacyAppeal) {

      //  If feature flag is true, filter out the chosen remand reasons.
      if (this.props.featureToggles.additional_remand_reasons) {
        this.filterSelectableLegacyRemandReasons('dueProcess', 0);
      }

      return (
        <div {...flexContainer}>
          <div {...flexColumn}>
            <CheckboxGroup
              label={<h3>Medical examination and opinion</h3>}
              name="med-exam"
              options={LEGACY_REMAND_REASONS.medicalExam}
              {...checkboxGroupProps}
            />
            <CheckboxGroup
              label={<h3>Duty to assist records request</h3>}
              name="duty-to-assist"
              options={LEGACY_REMAND_REASONS.dutyToAssistRecordsRequest}
              {...checkboxGroupProps}
            />
          </div>
          <div {...flexColumn}>
            <CheckboxGroup
              label={<h3>Duty to notify</h3>}
              name="duty-to-notify"
              options={LEGACY_REMAND_REASONS.dutyToNotify}
              {...checkboxGroupProps}
            />
            <CheckboxGroup
              label={<h3>Due process</h3>}
              name="due-process"
              options={LEGACY_REMAND_REASONS.dueProcess}
              {...checkboxGroupProps}
            />
          </div>
        </div>
      );
    }

    return (
      <div {...flexContainer}>
        <div {...flexColumn}>
          <CheckboxGroup
            label={<h3>Duty to notify</h3>}
            name="duty-to-notify"
            options={REMAND_REASONS.dutyToNotify}
            {...checkboxGroupProps}
          />
          <CheckboxGroup
            label={<h3>Duty to assist</h3>}
            name="duty-to-assist"
            options={REMAND_REASONS.dutyToAssist}
            {...checkboxGroupProps}
          />
        </div>
        <div {...flexColumn}>
          <CheckboxGroup
            label={<h3>Medical examination and opinion</h3>}
            name="medical-exam"
            options={REMAND_REASONS.medicalExam}
            {...checkboxGroupProps}
          />
          <br />
          <CheckboxGroup
            label={<h3>Other</h3>}
            name="other"
            options={REMAND_REASONS.other}
            {...checkboxGroupProps}
          />
        </div>
      </div>
    );
  };

  render = () => {
    const { issue, issues, idx, highlight, appeal } = this.props;

    return (
      <div key={`remand-reasons-${String(issue.id)}`}>
        <h2 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
          Issue {idx + 1} {issues.length > 1 ? ` of ${issues.length}` : ''}
        </h2>
        <div {...smallBottomMargin}>
          {appeal.isLegacyAppeal ?
            `Program: ${getIssueProgramDescription(issue)}` :
            `Benefit type: ${BENEFIT_TYPES[issue.benefit_type]}`}
        </div>
        {!appeal.isLegacyAppeal && <div {...smallBottomMargin}>Issue description: {issue.description}</div>}
        {appeal.isLegacyAppeal && (
          <React.Fragment>
            <div {...smallBottomMargin}>Issue: {getIssueTypeDescription(issue)}</div>
            <div {...smallBottomMargin}>Code: {getIssueDiagnosticCodeLabel(last(issue.codes))}</div>
            <div {...smallBottomMargin} ref={(node) => (this.elTopOfWarning = node)}>
              Certified: {formatDateStr(appeal.certificationDate)}
            </div>
            <div {...smallBottomMargin}>Note: {issue.note}</div>
          </React.Fragment>
        )}
        {highlight && !this.getChosenOptions().length && (
          <div className="usa-input-error" {...css(redText, boldText, errorNoTopMargin)}>
            Choose at least one
          </div>
        )}
        {this.getCheckboxGroup()}
      </div>
    );
  };
}

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.stagedChanges.appeals[ownProps.appealId];
  const issues = appeal.isLegacyAppeal ? appeal.issues : appeal.decisionIssues;

  return {
    appeal,
    issues: filter(issues, (issue) =>
      [VACOLS_DISPOSITIONS.REMANDED, ISSUE_DISPOSITIONS.REMANDED].includes(issue.disposition)
    ),
    issue: find(issues, (issue) => issue.id === ownProps.issueId),
    highlight: state.ui.highlightFormItems
  };
};

IssueRemandReasonsOptions.propTypes = {
  appeal: PropTypes.object,
  issues: PropTypes.array,
  issue: PropTypes.object,
  issueId: PropTypes.number,
  highlight: PropTypes.bool,
  idx: PropTypes.number,
  featureToggles: PropTypes.object,
};

export default connect(
  mapStateToProps,
  null,
  null,
  { forwardRef: true }
)(IssueRemandReasonsOptions);
