import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';
import { formatDateStr } from '../../util/DateUtil';
import scrollToComponent from 'react-scroll-to-component';

import Checkbox from '../../components/Checkbox';
import CheckboxGroup from '../../components/CheckboxGroup';
import RadioField from '../../components/RadioField';

import {
  getIssueProgramDescription,
  getIssueTypeDescription,
  getIssueDiagnosticCodeLabel
} from '../utils';
import {
  startEditingAppealIssue,
  saveEditedAppealIssue
} from '../QueueActions';
import {
  fullWidth,
  REMAND_REASONS,
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
  constructor(props) {
    super(props);

    const options = _.concat(..._.values(REMAND_REASONS));
    const pairs = _.zip(
      _.map(options, 'id'),
      _.map(options, () => ({
        checked: false,
        after_certification: null
      }))
    );

    this.state = _.fromPairs(pairs);
  }

  updateIssue = (attributes) => {
    const { appealId, issueId } = this.props;

    this.props.startEditingAppealIssue(appealId, issueId, attributes);
    this.props.saveEditedAppealIssue(appealId);
  };

  getChosenOptions = () => _.filter(this.state, (val) => val.checked);

  validateChosenOptionsHaveCertification = () => {
    const chosenOptions = this.getChosenOptions();
    const chosenOptionsWithCertification = _.filter(chosenOptions, (opt) => !_.isNull(opt.after_certification));

    return chosenOptions.length === chosenOptionsWithCertification.length;
  };

  validate = () => this.getChosenOptions().length >= 1 &&
    this.validateChosenOptionsHaveCertification();

  // todo: make scrollTo util function that also sets focus
  // element focus info https://goo.gl/jCkoxP
  scrollTo = (dest = this, opts) => scrollToComponent(dest, _.defaults(opts, {
    align: 'top',
    duration: 1500,
    ease: 'outCube',
    offset: -35
  }));

  componentDidMount = () => {
    const {
      issue: {
        vacols_sequence_id: issueId,
        remand_reasons: remandReasons
      },
      issues
    } = this.props;

    _.each(remandReasons, (reason) => this.setState({
      [reason.code]: {
        checked: true,
        after_certification: reason.after_certification.toString()
      }
    }));

    if (_.map(issues, 'vacols_sequence_id').indexOf(issueId) > 0) {
      this.scrollTo();
    }
  };

  componentWillUnmount = () => {
    // on unmount, update issue attrs from state
    // "remand_reasons": [
    //   {"code": "AB", "after_certification": true},
    //   {"code": "AC", "after_certification": false}
    // ]
    const remandReasons = _(this.state).
      map((val, key) => {
        if (!val.checked) {
          return false;
        }

        return {
          code: key,
          after_certification: val.after_certification === 'true'
        };
      }).
      compact().
      value();

    this.updateIssue({ remand_reasons: remandReasons });
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

  toggleRemandReason = (checked, event) => this.setState({
    [event.target.id.split('-')[1]]: {
      checked,
      after_certification: null
    }
  });

  getCheckbox = (option, onChange, values) => {
    const rowOptId = `${this.props.issue.vacols_sequence_id}-${option.id}`;

    return <React.Fragment key={option.id}>
      <Checkbox
        name={rowOptId}
        onChange={onChange}
        value={values[option.id].checked}
        label={option.label}
        unpadded />
      {values[option.id].checked && <RadioField
        errorMessage={this.props.highlight && _.isNull(this.state[option.id].after_certification) && 'Choose one'}
        styling={css(smallLeftMargin, smallBottomMargin, errorNoTopMargin)}
        name={rowOptId}
        vertical
        hideLabel
        options={[{
          displayText: 'Before certification',
          value: 'false'
        }, {
          displayText: 'After certification',
          value: 'true'
        }]}
        value={this.state[option.id].after_certification}
        onChange={(afterCertification) => this.setState({
          [option.id]: {
            checked: true,
            after_certification: afterCertification
          }
        })}
      />}
    </React.Fragment>;
  };

  render = () => {
    const {
      issue,
      issues,
      idx,
      highlight,
      appeal: { attributes: appeal }
    } = this.props;
    const checkboxGroupProps = {
      onChange: this.toggleRemandReason,
      getCheckbox: this.getCheckbox,
      values: this.state
    };

    return <div key={`remand-reasons-${issue.vacols_sequence_id}`}>
      <h2 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
        Issue {idx + 1} {issues.length > 1 ? ` of ${issues.length}` : ''}
      </h2>
      <div {...smallBottomMargin}>Program: {getIssueProgramDescription(issue)}</div>
      <div {...smallBottomMargin}>Issue: {getIssueTypeDescription(issue)}</div>
      <div {...smallBottomMargin}>
        Code: {getIssueDiagnosticCodeLabel(_.last(issue.codes))}
      </div>
      <div {...smallBottomMargin} ref={(node) => this.elTopOfWarning = node}>
        Certified: {formatDateStr(appeal.certification_date)}
      </div>
      {highlight && !this.getChosenOptions().length &&
        <div className="usa-input-error"
          {...css(redText, boldText, errorNoTopMargin)}>
          Choose at least one
        </div>
      }

      <div {...flexContainer}>
        <div {...flexColumn}>
          <CheckboxGroup
            label={<h3>Medical examination and opinion</h3>}
            name="med-exam"
            options={REMAND_REASONS.medicalExam}
            {...checkboxGroupProps} />
          <CheckboxGroup
            label={<h3>Duty to assist records request</h3>}
            name="duty-to-assist"
            options={REMAND_REASONS.dutyToAssistRecordsRequest}
            {...checkboxGroupProps} />
        </div>
        <div {...flexColumn}>
          <CheckboxGroup
            label={<h3>Duty to notify</h3>}
            name="duty-to-notify"
            options={REMAND_REASONS.dutyToNotify}
            {...checkboxGroupProps} />
          <CheckboxGroup
            label={<h3>Due process</h3>}
            name="due-process"
            options={REMAND_REASONS.dueProcess}
            {...checkboxGroupProps} />
        </div>
      </div>
    </div>;
  };
}

IssueRemandReasonsOptions.propTypes = {
  appealId: PropTypes.string.isRequired,
  issueId: PropTypes.number.isRequired,
  idx: PropTypes.number.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.stagedChanges.appeals[ownProps.appealId];
  const issues = appeal.attributes.issues;

  return {
    appeal,
    issues: _.filter(issues, (issue) => issue.disposition === 'Remanded'),
    issue: _.find(issues, (issue) => issue.vacols_sequence_id === ownProps.issueId),
    highlight: state.ui.highlightFormItems
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  startEditingAppealIssue,
  saveEditedAppealIssue
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps, null, { withRef: true })(IssueRemandReasonsOptions);
