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
  saveEditedAppealIssue,
  deleteAppealIssue,
  editAppeal
} from './QueueActions';
import {
  highlightInvalidFormItems,
  requestUpdate,
  requestDelete,
  showModal,
  hideModal,
  requestSave
} from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import SearchableDropdown from '../components/SearchableDropdown';
import TextField from '../components/TextField';
import Button from '../components/Button';
import Modal from '../components/Modal';
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
    const { issueId, vacolsId } = this.props;

    if (this.props.action === 'edit') {
      this.props.startEditingAppealIssue(vacolsId, issueId);
    }
  };

  getFooterButtons = () => [{
    displayText: 'Go back to Select Dispositions'
  }, {
    displayText: 'Save'
  }];

  updateIssue = (attributes) => {
    this.props.highlightInvalidFormItems(false);
    this.props.updateEditingAppealIssue(attributes);
  };

  updateIssueCode = (codeIdx, code) => {
    let { issue: { codes } } = this.props;

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
      appeal,
      appeal: { attributes: { issues } }
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
    const issueIndex = _.map(issues, 'vacols_sequence_id').indexOf(issue.vacols_sequence_id);
    let url = `/appeals/${appeal.id}/issues`;
    let requestMethod = 'requestSave';
    let successMsg = 'You have created a new issue.';

    if (this.props.action === 'edit') {
      url += `/${issue.vacols_sequence_id}`;
      requestMethod = 'requestUpdate';
      successMsg = `You have updated issue ${issueIndex + 1}`
    }

    this.props[requestMethod](url, { data: params }, successMsg).
      then((response) => {
        const resp = JSON.parse(response.text);
        const updatedIssues = _.map(resp.issues.data, 'attributes');

        this.updateIssue(updatedIssues[0]);
        this.props.saveEditedAppealIssue(this.props.vacolsId);
      });
  };

  deleteIssue = () => {
    const {
      issue,
      appeal,
      appeal: { attributes: { issues } },
      vacolsId,
      issueId
    } = this.props;
    const issueIndex = _.map(issues, 'vacols_sequence_id').indexOf(issue.vacols_sequence_id);

    this.props.hideModal();

    this.props.requestDelete(
      `/appeals/${appeal.id}/issues/${issue.vacols_sequence_id}`, {},
      `You have deleted issue ${issueIndex + 1}.`
    ).then(() => {
      this.props.cancelEditingAppealIssue();
      this.props.deleteAppealIssue(vacolsId, issueId);
    });
  }

  renderIssueAttrs = (attrs = {}) => _.map(attrs, (obj, value) => ({
    label: obj.description,
    value
  }));

  render = () => {
    const {
      issue,
      action,
      highlight,
      error,
      modal
    } = this.props;

    const programs = ISSUE_INFO;
    const issues = _.get(programs[issue.program], 'issue');
    const [issueLevels1, issueLevels2, issueLevels3] = this.getIssueLevelOptions();

    // only highlight invalid fields with options (i.e. not disabled)
    const errorHighlightConditions = {
      program: highlight && !issue.program,
      type: highlight && !issue.type,
      level1: highlight && !issue.codes[0] && !_.isEmpty(issueLevels1),
      level2: highlight && !issue.codes[1] && !_.isEmpty(issueLevels2),
      level3: highlight && !issue.codes[2] && !_.isEmpty(issueLevels3)
    };

    return <React.Fragment>
      {modal && <div className="cf-modal-scroll">
        <Modal
          title="Delete Issue?"
          buttons={[{
            classNames: ['usa-button', 'cf-btn-link'],
            name: 'Close',
            onClick: this.props.hideModal
          }, {
            classNames: ['usa-button', 'usa-button-secondary'],
            name: 'Delete issue',
            onClick: this.deleteIssue
          }]}
          closeHandler={this.props.hideModal}>
          You are about to permanently delete this issue. To delete please
          click the <strong>"Delete issue"</strong> button or click&nbsp;
          <strong>"Close"</strong> to return to the previous screen.
        </Modal>
      </div>}
      <h1 {...css(fullWidth, smallBottomMargin)}>
        {StringUtil.titleCase(action)} Issue
      </h1>
      {error && <Alert type="error" title={error.title} styling={smallTopMargin}>
        {error.detail}
      </Alert>}
      <Button
        willNeverBeLoading
        linkStyling
        styling={noLeftPadding}
        onClick={this.props.showModal}>
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
          value={issue.program} />
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
          value={issue.type} />
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
  modal: state.ui.modal
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateEditingAppealIssue,
  startEditingAppealIssue,
  cancelEditingAppealIssue,
  saveEditedAppealIssue,
  highlightInvalidFormItems,
  deleteAppealIssue,
  requestUpdate,
  requestDelete,
  showModal,
  hideModal,
  requestSave,
  editAppeal
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(AddEditIssueView));
