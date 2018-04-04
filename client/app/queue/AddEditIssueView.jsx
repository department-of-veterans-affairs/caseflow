import React from 'react';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

import StringUtil from '../util/StringUtil';
import {
  updateEditingAppealIssue,
  startEditingAppealIssue,
  cancelEditingAppealIssue,
  saveEditedAppealIssue
} from './QueueActions';
import {
  highlightInvalidFormItems,
  requestUpdate
} from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import SearchableDropdown from '../components/SearchableDropdown';
import TextField from '../components/TextField';
import Button from '../components/Button';
import Alert from '../components/Alert';

import {
  fullWidth,
  ISSUE_INFO,
  ERROR_FIELD_REQUIRED
} from './constants';
const marginTop = css({ marginTop: '5rem' });
const dropdownMarginTop = css({ marginTop: '2rem' });
const smallTopMargin = css({ marginTop: '1rem' });
const smallBottomMargin = css({ marginBottom: '1rem' });
const noLeftPadding = css({ paddingLeft: 0 });

class AddEditIssueView extends React.Component {
  componentDidMount = () => {
    const {
      issueId,
      vacolsId
    } = this.props;

    this.props.startEditingAppealIssue(vacolsId, issueId);
  };

  getFooterButtons = () => [{
    displayText: '< Go back to Select Dispositions'
  }, {
    displayText: 'Save'
  }];

  updateIssue = (attributes) => {
    this.props.highlightInvalidFormItems(false);
    this.props.updateEditingAppealIssue(attributes);
  };

  updateIssueCode = (codeIdx, code) => {
    let {
      issue: { codes }
    } = this.props;

    // remove more-specific issue levels on change
    // i.e. on change Issue, remove all Levels
    codes[codeIdx] = code;
    codes = _.take(codes, codeIdx + 1);

    this.updateIssue({ codes });
  };

  getIssueLevelOptions = () => {
    const {
      issue: {
        program,
        type,
        codes
      }
    } = this.props;
    const vacolsIssues = _.get(ISSUE_INFO[program], 'issue', {});
    const issueLevel1 = _.get(vacolsIssues, [type, 'levels'], {});
    const issueLevel2 = _.get(issueLevel1, [_.get(codes, 0), 'levels'], {});
    const issueLevel3 = _.get(issueLevel2, [_.get(codes, 1), 'levels'], {});

    return [issueLevel1, issueLevel2, issueLevel3];
  };

  goToPrevStep = () => {
    this.props.cancelEditingAppealIssue();

    return true;
  };

  validateForm = () => {
    const { issue: { codes } } = this.props;

    return this.getIssueLevelOptions().every((level, idx) =>
      _.isEmpty(level) || (codes[idx] in level)
    );
  };

  goToNextStep = () => {
    const {
      issue,
      appeal
    } = this.props;
    const params = {
      issues: {
        ..._.pick(issue, 'note', 'program'),
        issue: issue.type,
        level_1: _.get(issue.codes, 0),
        level_2: _.get(issue.codes, 1),
        level_3: _.get(issue.codes, 2)
      }
    };

    this.props.requestUpdate(
      `/appeals/${appeal.id}/issues/${issue.vacols_sequence_id}`,
      { data: params }
    ).then(() => this.props.saveEditedAppealIssue(this.props.vacolsId));
  };

  renderIssueAttrs = (attrs = {}) => _.map(attrs, (obj, value) => ({
    label: obj.description,
    value
  }));

  render = () => {
    const {
      issue: {
        program,
        type,
        codes
      },
      action,
      highlight,
      error
    } = this.props;

    const programs = ISSUE_INFO;
    const issues = _.get(programs[program], 'issue');
    const [issueLevels1, issueLevels2, issueLevels3] = this.getIssueLevelOptions();

    // only highlight invalid fields with options (i.e. not disabled)
    const errorHighlightConditions = {
      program: highlight && !program,
      type: highlight && !type,
      level1: highlight && !codes[0] && !_.isEmpty(issueLevels1),
      level2: highlight && !codes[1] && !_.isEmpty(issueLevels2),
      level3: highlight && !codes[2] && !_.isEmpty(issueLevels3)
    };

    return <React.Fragment>
      <h1 {...css(fullWidth, smallBottomMargin)}>
        {StringUtil.titleCase(action)} Issue
      </h1>
      {error.message && <Alert type="error" title={error.message.title} styling={smallTopMargin}>
        {error.message.detail}
      </Alert>}
      <Button
        willNeverBeLoading
        styling={noLeftPadding}
        classNames={['cf-btn-link']}
        onClick={_.noop}>
        Delete Issue
      </Button>
      <div {...dropdownMarginTop}>
        <SearchableDropdown
          required
          name="Program:"
          placeholder="Select program"
          options={this.renderIssueAttrs(programs)}
          onChange={({ value }) => this.updateIssue({
            program: value,
            type: null
          })}
          errorMessage={errorHighlightConditions.program ? ERROR_FIELD_REQUIRED : ''}
          value={program} />
      </div>
      <div {...dropdownMarginTop}>
        <SearchableDropdown
          required
          name="Issue:"
          placeholder="Select issue"
          options={this.renderIssueAttrs(issues)}
          onChange={({ value }) => this.updateIssue({
            type: value,
            // unset issue levels for validation
            codes: []
          })}
          errorMessage={errorHighlightConditions.type ? ERROR_FIELD_REQUIRED : ''}
          value={type} />
      </div>
      <h3 {...marginTop}>Subsidiary Questions or Other Tracking Identifier(s)</h3>
      <div {...dropdownMarginTop}>
        <SearchableDropdown
          name="Level 1:"
          placeholder="Select level 1"
          options={this.renderIssueAttrs(issueLevels1)}
          onChange={({ value }) => this.updateIssueCode(0, value)}
          readOnly={_.isEmpty(issueLevels1)}
          errorMessage={errorHighlightConditions.level1 ? ERROR_FIELD_REQUIRED : ''}
          value={_.get(this.props.issue, 'codes[0]', '')} />
      </div>
      <div {...dropdownMarginTop}>
        <SearchableDropdown
          name="Level 2:"
          placeholder="Select level 2"
          options={this.renderIssueAttrs(issueLevels2)}
          onChange={({ value }) => this.updateIssueCode(1, value)}
          readOnly={_.isEmpty(issueLevels2)}
          errorMessage={errorHighlightConditions.level2 ? ERROR_FIELD_REQUIRED : ''}
          value={_.get(this.props.issue, 'codes[1]', '')} />
      </div>
      <div {...dropdownMarginTop}>
        <SearchableDropdown
          name="Level 3:"
          placeholder="Select level 3"
          options={this.renderIssueAttrs(issueLevels3)}
          onChange={({ value }) => this.updateIssueCode(2, value)}
          readOnly={_.isEmpty(issueLevels3)}
          errorMessage={errorHighlightConditions.level3 ? ERROR_FIELD_REQUIRED : ''}
          value={_.get(this.props.issue, 'codes[2]', '')} />
      </div>
      <TextField
        name="Notes:"
        value={_.get(this.props.issue, 'note', '')}
        onChange={(value) => this.updateIssue({ note: value })} />
    </React.Fragment>;
  };
}

AddEditIssueView.propTypes = {
  action: PropTypes.oneOf(['add', 'edit']).isRequired,
  vacolsId: PropTypes.string.isRequired,
  nextStep: PropTypes.string.isRequired,
  prevStep: PropTypes.string.isRequired,
  issueId: PropTypes.string,
  appeal: PropTypes.object,
  issue: PropTypes.object
};

const mapStateToProps = (state, ownProps) => ({
  highlight: state.ui.highlightFormItems,
  appeal: state.queue.pendingChanges.appeals[ownProps.vacolsId],
  task: state.queue.loadedQueue.tasks[ownProps.vacolsId],
  issue: state.queue.editingIssue,
  error: state.ui.messages.error,
  ..._.pick(state.ui, 'savePending', 'saveSuccessful')
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateEditingAppealIssue,
  startEditingAppealIssue,
  cancelEditingAppealIssue,
  saveEditedAppealIssue,
  highlightInvalidFormItems,
  requestUpdate
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(AddEditIssueView));
