import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import CheckboxGroup from '../../components/CheckboxGroup';
import RadioField from '../../components/RadioField';

import {
  getIssueProgramDescription,
  getIssueTypeDescription
} from '../utils';
import {
  startEditingAppealIssue,
  saveEditedAppealIssue
} from '../QueueActions';
import {
  fullWidth,
  REMAND_REASONS
} from '../constants';

const smallLeftMargin = css({ marginLeft: '1rem' });
const smallBottomMargin = css({ marginBottom: '1rem' });
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
        after_certification: 'false'
      }))
    );

    this.state = _.fromPairs(pairs);
  }

  updateIssue = (attributes) => {
    const { appealId, issueId } = this.props;

    this.props.startEditingAppealIssue(appealId, issueId, attributes);
    this.props.saveEditedAppealIssue(appealId);
  };

  componentDidMount = () => _.each(this.props.issue.remand_reasons, (reason) => this.setState({
    [reason.code]: {
      checked: true,
      after_certification: reason.after_certification
    }
  }));

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
          ..._.pick(val, 'after_certification')
        };
      }).
      compact().
      value();

    this.updateIssue({ remand_reasons: remandReasons });
  }

  toggleRemandReason = (event) => this.setState({
    [event.target.id]: {
      checked: event.target.checked,
      after_certification: 'false'
    }
  });

  getCheckbox = (option, onChange, values) => <div className="checkbox" key={option.id}>
    <input
      name={option.id}
      onChange={onChange}
      type="checkbox"
      id={option.id}
      checked={values[option.id].checked}
    />
    <label htmlFor={option.id}>
      {option.label}
    </label>
    {values[option.id].checked && <RadioField
      id={option.id}
      vertical
      key={`${option.id}-after-certification`}
      styling={css(smallLeftMargin, smallBottomMargin)}
      name={`${option.id}-after-cert-radio-btns`}
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
  </div>;

  render = () => {
    const {
      issue,
      idx
    } = this.props;
    const checkboxGroupProps = {
      onChange: this.toggleRemandReason,
      getCheckbox: this.getCheckbox,
      values: this.state
    };

    return <div key={`remand-reasons-${issue.vacols_sequence_id}`}>
      <h2 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>Issue {idx + 1}</h2>
      <div {...smallBottomMargin}>Program: {getIssueProgramDescription(issue)}</div>
      <div {...smallBottomMargin}>Issue: {getIssueTypeDescription(issue)}</div>
      <div {...smallBottomMargin}>Code: {_.last(issue.description)}</div>
      {/* todo: certified date */}
      <div {...smallBottomMargin}>Certified: {(issue.date_assigned || new Date().toISOString()).split('T')[0]}</div>

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
  const appeal = state.queue.pendingChanges.appeals[ownProps.appealId];
  const issues = appeal.attributes.issues;

  return {
    issue: _.find(issues, (issue) => issue.vacols_sequence_id === ownProps.issueId)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  startEditingAppealIssue,
  saveEditedAppealIssue
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(IssueRemandReasonsOptions);
