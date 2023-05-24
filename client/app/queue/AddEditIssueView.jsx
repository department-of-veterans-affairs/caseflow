const PropTypes = require('prop-types');

import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

import StringUtil from '../util/StringUtil';
import {
  updateEditingAppealIssue,
  startEditingAppealIssue,
  cancelEditingAppealIssue,
  saveEditedAppealIssue,
  deleteEditingAppealIssue
} from './QueueActions';
import {
  highlightInvalidFormItems,
  requestUpdate,
  requestDelete,
  showModal,
  hideModal,
  requestSave
} from './uiReducer/uiActions';
import {
  getIssueDiagnosticCodeLabel,
  prepareAppealIssuesForStore
} from './utils';

import SearchableDropdown from '../components/SearchableDropdown';
import TextField from '../components/TextField';
import Button from '../components/Button';
import Modal from '../components/Modal';
import Alert from '../components/Alert';
import Checkbox from '../components/Checkbox';

import {
  fullWidth,
  ISSUE_DESCRIPTION_MAX_LENGTH
} from './constants';
import ISSUE_INFO from '../../constants/ISSUE_INFO';
import DIAGNOSTIC_CODE_DESCRIPTIONS from '../../constants/DIAGNOSTIC_CODE_DESCRIPTIONS';
import QueueFlowPage from './components/QueueFlowPage';

const marginTop = css({ marginTop: '5rem' });
const dropdownMarginTop = css({ marginTop: '2rem' });
const smallTopMargin = css({ marginTop: '1rem' });
const smallBottomMargin = css({ marginBottom: '1rem' });
const noLeftPadding = css({ paddingLeft: 0 });
const checkboxStyle = css({ marginTop: '0', marginBottom: '0' });

class AddEditIssueView extends React.Component {

  componentDidMount = () => {
    const { issueId, appealId } = this.props;

    this.props.cancelEditingAppealIssue();
    if (this.props.action === 'edit') {
      this.props.startEditingAppealIssue(appealId, issueId);
    }
  };

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
    const { issue: { program, type, codes } } = this.props;
    const vacolsIssues = _.get(ISSUE_INFO[program], 'levels', {});
    const issueLevel1 = _.get(vacolsIssues, [type, 'levels'], {});
    const issueLevel2 = _.get(issueLevel1, [_.get(codes, 0), 'levels'], {});

    return [issueLevel1, issueLevel2];
  };

  validateForm = () => {
    const { issue: { program, type, codes } } = this.props;
    const issueDiagCode = _.find(codes, (code) => code.length === 4);

    if (this.issueLevelsConfigHasDiagCode() && !issueDiagCode) {
      return false;
    }

    return program && type && this.getIssueLevelOptions().every((level, idx) =>
      _.isEmpty(level) || (codes[idx] in level)
    );
  };

  goToNextStep = () => {
    const {
      issue,
      appeal,
      appeal: { issues }
    } = this.props;
    const params = {
      data: {
        issues: {
          issue: issue.type,
          level_1: _.get(issue.codes, 0, null),
          level_2: _.get(issue.codes, 1, null),
          level_3: _.get(issue.codes, 2, null),
          ..._.pick(issue, 'note', 'program'),
          mst_status: issue.legacy_appeal_vacols_mst ? 'Y' : 'N',
          pact_status: issue.legacy_appeal_vacols_pact ? 'Y' : 'N'
        }
      }
    };
    const issueIndex = _.map(issues, 'id').indexOf(issue.id);
    const url = `/appeals/${appeal.externalId}/issues`;
    let requestPromise;

    if (this.props.action === 'add') {
      requestPromise = this.props.requestSave(url, params, { title: 'You created a new issue.' });
    } else {
      requestPromise = this.props.requestUpdate(
        `${url}/${String(issue.id)}`, params,
        { title: `You updated issue ${issueIndex + 1}.` }
      );
    }

    requestPromise.then((resp) => this.updateIssuesFromServer(resp.body)).
      catch(() => {
        // handle the error from the frontend
      });
  };

  updateIssuesFromServer = (response) => {
    const { appeal } = this.props;

    this.props.saveEditedAppealIssue(this.props.appealId, {
      issues: prepareAppealIssuesForStore({
        attributes: {
          issues: response.issues,
          docket_name: appeal.docketName
        }
      })
    });
  }

  deleteIssue = () => {
    const {
      issue,
      appeal: { issues },
      appealId,
      issueId
    } = this.props;
    const issueIndex = _.map(issues, 'id').indexOf(issue.id);

    this.props.hideModal('deleteIssue');

    this.props.requestDelete(
      `/appeals/${appealId}/issues/${String(issue.id)}`, {},
      { title: `You deleted issue ${issueIndex + 1}.` }
    ).then((resp) => this.props.deleteEditingAppealIssue(appealId, issueId, resp.body));
  };

  renderDiagnosticCodes = () => _.keys(DIAGNOSTIC_CODE_DESCRIPTIONS).map((value) => ({
    label: getIssueDiagnosticCodeLabel(value),
    value
  }));

  renderIssueAttrs = (attrs = {}) => _.map(attrs, (obj, value) => ({
    label: obj.description,
    value
  }));

  issueLevelsConfigHasDiagCode = () => {
    const {
      issue
    } = this.props;
    const issueLevels = this.getIssueLevelOptions();

    if (!issue.codes || !issue.codes.length) {
      return false;
    }

    const lastIssueLevel = _.last(_.reject(issueLevels, _.isEmpty));
    const lastIssueLevelCode = _.findLast(issue.codes, (code) => code.length === 2);

    // if issueLevels[n] has options and issue.codes[n].length is 2 (issue level), check diagnostic_code
    if (issueLevels.indexOf(lastIssueLevel) === _.lastIndexOf(issue.codes, lastIssueLevelCode)) {
      return _.get(lastIssueLevel[lastIssueLevelCode], 'diagnostic_code') || false;
    }

    return false;
  };

  render = () => {
    const {
      issue,
      action,
      highlight,
      error,
      deleteIssueModal,
      ...otherProps
    } = this.props;

    const programs = ISSUE_INFO;
    const issues = _.get(programs[issue.program], 'levels');
    const issueLevels = this.getIssueLevelOptions();

    // only highlight invalid fields with options (i.e. not disabled)
    const errorHighlightConditions = {
      program: highlight && !issue.program,
      type: highlight && !issue.type,
      level1: highlight && !_.get(issue, 'codes[0]') && !_.isEmpty(issueLevels[0]),
      level2: highlight && !_.get(issue, 'codes[1]') && !_.isEmpty(issueLevels[1]),
      diagCode: highlight && this.issueLevelsConfigHasDiagCode() && !_.find(issue.codes, (code) => code.length === 4)
    };

    return <QueueFlowPage
      validateForm={this.validateForm}
      goToNextStep={this.goToNextStep}
      {...otherProps}
    >
      {deleteIssueModal && <div className="cf-modal-scroll">
        <Modal
          title="Delete Issue?"
          buttons={[{
            classNames: ['usa-button', 'cf-btn-link'],
            name: 'Close',
            onClick: () => this.props.hideModal('deleteIssue')
          }, {
            classNames: ['usa-button', 'usa-button-secondary'],
            name: 'Delete issue',
            onClick: this.deleteIssue
          }]}
          closeHandler={() => this.props.hideModal('deleteIssue')}>
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
        disabled={!issue.id}
        styling={noLeftPadding}
        onClick={() => this.props.showModal('deleteIssue')}>
        Delete Issue
      </Button>
      <div {...dropdownMarginTop}>
        <SearchableDropdown
          required
          name="Program:"
          placeholder="Select program"
          options={this.renderIssueAttrs(programs)}
          onChange={(option) => option && this.updateIssue({
            program: option.value,
            type: null,
            codes: []
          })}
          errorMessage={errorHighlightConditions.program ? 'program field is required' : ''}
          value={issue.program} />
      </div>
      <div {...dropdownMarginTop}>
        <SearchableDropdown
          required
          name="Issue:"
          placeholder="Select issue"
          readOnly={!issue.program}
          options={this.renderIssueAttrs(issues)}
          onChange={(option) => option && this.updateIssue({
            type: option.value,
            // unset issue levels for validation
            codes: []
          })}
          errorMessage={errorHighlightConditions.type ? 'Issue field is required' : ''}
          value={issue.type} />
      </div>
      <h3 {...marginTop}>Subsidiary Questions or Other Tracking Identifiers</h3>
      <div {...dropdownMarginTop}>
        <SearchableDropdown
          name="Level 1:"
          placeholder="Select level 1"
          options={this.renderIssueAttrs(issueLevels[0])}
          onChange={(option) => option && this.updateIssueCode(0, option.value)}
          readOnly={_.isEmpty(issueLevels[0])}
          errorMessage={errorHighlightConditions.level1 ? 'Level field is required' : ''}
          value={_.get(issue, 'codes[0]', '')} />
      </div>
      {!_.isEmpty(issueLevels[1]) && <div {...dropdownMarginTop}>
        <SearchableDropdown
          name="Level 2:"
          placeholder="Select level 2"
          options={this.renderIssueAttrs(issueLevels[1])}
          onChange={(option) => option && this.updateIssueCode(1, option.value)}
          errorMessage={errorHighlightConditions.level2 ? 'Level field is required' : ''}
          value={_.get(issue, 'codes[1]', '')} />
      </div>}
      {this.issueLevelsConfigHasDiagCode() && <div {...dropdownMarginTop}>
        <SearchableDropdown
          name="Diagnostic code"
          placeholder="Select diagnostic code"
          options={this.renderDiagnosticCodes()}
          onChange={(option) => {
            if (!option || !option.value) {
              return;
            }
            const { codes } = issue;

            if (codes.length && _.last(codes).length === 4) {
              codes.splice(codes.length - 1, 1, option.value);
            } else {
              codes.push(option.value);
            }

            this.updateIssue({ codes });
          }}
          value={_.last(issue.codes)}
          errorMessage={errorHighlightConditions.diagCode ? 'Diagnostic code is required' : ''} />
      </div>}
      <TextField
        name="Notes:"
        value={_.get(this.props.issue, 'note', '')}
        maxLength={ISSUE_DESCRIPTION_MAX_LENGTH}
        onChange={(value) => this.updateIssue({ note: value })} />
      <label style={{ marginBottom: '1rem' }}>Select any special issues that apply</label>
      <Checkbox
        name="MST"
        label="Military Sexual Trauma (MST)"
        // defaultValue={issue.legacy_appeal_vacols_mst}
        value={issue.mst_status}
        styling={checkboxStyle}
        onChange={(checked) => this.updateIssue({ mst_status: checked })}
      />
      <Checkbox
        name="PACT"
        label="PACT Act"
        // defaultValue={issue.legacy_appeal_vacols_pact}
        value={issue.pact_status}
        styling={checkboxStyle}
        onChange={(checked) => this.updateIssue({ pact_status: checked })}
      />
    </QueueFlowPage>;
  };
}

AddEditIssueView.propTypes = {
  action: PropTypes.string,
  appeal: PropTypes.shape({
    docketName: PropTypes.string,
    externalId: PropTypes.string,
    issues: PropTypes.object
  }),
  appealId: PropTypes.string,
  cancelEditingAppealIssue: PropTypes.func,
  codes: PropTypes.arrayOf(PropTypes.string),
  deleteEditingAppealIssue: PropTypes.func,
  deleteIssueModal: PropTypes.bool,
  detail: PropTypes.string,
  docketName: PropTypes.string,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  externalId: PropTypes.string,
  hideModal: PropTypes.func,
  highlight: PropTypes.bool,
  highlightInvalidFormItems: PropTypes.func,
  id: PropTypes.number,
  issue: PropTypes.shape({
    id: PropTypes.number,
    type: PropTypes.string,
    codes: PropTypes.arrayOf(PropTypes.string),
    program: PropTypes.string,
    legacy_appeal_vacols_mst: PropTypes.bool,
    legacy_appeal_vacols_pact: PropTypes.bool
  }),
  issueId: PropTypes.string,
  issues: PropTypes.object,
  requestDelete: PropTypes.func,
  requestSave: PropTypes.func,
  requestUpdate: PropTypes.func,
  saveEditedAppealIssue: PropTypes.func,
  showModal: PropTypes.func,
  startEditingAppealIssue: PropTypes.func,
  title: PropTypes.string,
  type: PropTypes.string,
  updateEditingAppealIssue: PropTypes.func
};

const mapStateToProps = (state, ownProps) => ({
  highlight: state.ui.highlightFormItems,
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  issue: state.queue.editingIssue,
  error: state.ui.messages.error,
  deleteIssueModal: state.ui.modals.deleteIssue
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateEditingAppealIssue,
  startEditingAppealIssue,
  cancelEditingAppealIssue,
  saveEditedAppealIssue,
  highlightInvalidFormItems,
  deleteEditingAppealIssue,
  requestUpdate,
  requestDelete,
  showModal,
  hideModal,
  requestSave
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AddEditIssueView);
