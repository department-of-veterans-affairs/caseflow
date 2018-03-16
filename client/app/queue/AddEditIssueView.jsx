import React from 'react';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

import StringUtil from '../util/StringUtil';
import {
  updateAppealIssue,
  startEditingAppealIssue,
  cancelEditingAppealIssue,
  saveEditedAppealIssue
} from './QueueActions';

import decisionViewBase from './components/DecisionViewBase';
import SearchableDropdown from '../components/SearchableDropdown';
import TextField from '../components/TextField';
import Button from '../components/Button';

import {
  fullWidth,
  ISSUE_INFO
} from './constants';
const marginTop = css({ marginTop: '5rem' });
const dropdownMarginTop = css({ marginTop: '2rem' });
const smallBottomMargin = css({ marginBottom: '1rem' });
const noLeftPadding = css({ paddingLeft: 0 });

const itemList = [{
  label: 'First',
  value: 1
}, {
  label: 'Second',
  value: 2
}, {
  label: 'Third',
  value: 3
}, {
  label: 'All Others',
  value: 'All Others'
}, {
  label: 'Thigh, limitation of flexion of',
  value: 'Thigh, limitation of flexion of'
}, {
  label: 'Compensation',
  value: 'compensation'
}];

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

  updateIssue = (attributes) => this.props.updateAppealIssue(
    this.props.vacolsId,
    this.props.issueId,
    attributes
  );

  getIssueValue = (value) => _.get(this.props.issue, value, '');

  goToPrevStep = () => {
    this.props.cancelEditingAppealIssue();

    return true;
  }

  validateForm = () => {
    // const { issue } = this.props;
    // const fields = ['program', 'type', 'levels', 'note'];
    // const missingFields = _.filter(fields, (field) => _.has(issue, field));
    //
    // return !missingFields.length;

    // todo: move to goToNextStep hook once `connect-omo-to-backend` merged
    this.props.saveEditedAppealIssue(this.props.vacolsId, this.props.issueId);

    return true;
  };

  getProgramIssues = (issprog) => {
    if (!issprog) {
      return [];
    }

    return _.map(ISSUE_INFO[issprog].issue, (obj, value) => ({
      label: obj.description,
      value
    }));
  };

  render = () => <React.Fragment>
    <h1 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
      {StringUtil.titleCase(this.props.action)} Issue
    </h1>
    <Button
      willNeverBeLoading
      styling={noLeftPadding}
      classNames={['cf-btn-link']}
      onClick={_.noop}>
      Delete Issue
    </Button>
    <SearchableDropdown
      name="Program:"
      styling={dropdownMarginTop}
      placeholder="Select program"
      options={_.map(ISSUE_INFO, (obj, value) => ({
        label: obj.description,
        value
      }))}
      onChange={({ value }) => this.updateIssue({ program: value })}
      value={this.getIssueValue('program')} />
    <SearchableDropdown
      name="Issue:"
      styling={dropdownMarginTop}
      placeholder="Select issue"
      options={this.getProgramIssues(this.getIssueValue('program'))}
      onChange={({ value }) => this.updateIssue({ type: value })}
      value={this.getIssueValue('type')} />
    <SearchableDropdown
      name="Add Stay:"
      styling={dropdownMarginTop}
      placeholder="Select stay"
      options={itemList}
      onChange={({ value }) => this.updateIssue({ stay: value })}
      value={this.getIssueValue('stay')} />
    <h3 {...marginTop}>Subsidiary Questions or Other Tracking Identifier(s)</h3>
    <SearchableDropdown
      name="Level 1:"
      styling={dropdownMarginTop}
      placeholder="Select level 1"
      options={itemList}
      onChange={({ value }) => this.updateIssue({ level1: value })}
      value={this.getIssueValue('levels[0]')} />
    <SearchableDropdown
      name="Level 2:"
      styling={dropdownMarginTop}
      placeholder="Select level 2"
      options={itemList}
      onChange={({ value }) => this.updateIssue({ level2: value })}
      value={this.getIssueValue('levels[1]')} />
    <SearchableDropdown
      name="Level 3:"
      styling={dropdownMarginTop}
      placeholder="Select level 3"
      options={itemList}
      onChange={({ value }) => this.updateIssue({ level3: value })}
      value={this.getIssueValue('levels[2]')} />
    <TextField
      name="Notes:"
      value={this.getIssueValue('note')}
      required={false}
      onChange={(value) => this.updateIssue({ note: value })} />
  </React.Fragment>;
}

AddEditIssueView.propTypes = {
  action: PropTypes.oneOf(['add', 'edit']).isRequired,
  vacolsId: PropTypes.string.isRequired,
  nextStep: PropTypes.string.isRequired,
  prevStep: PropTypes.string.isRequired,
  issueId: PropTypes.string.isRequired,
  appeal: PropTypes.object,
  issue: PropTypes.object
};

const mapStateToProps = (state, ownProps) => ({
  highlight: state.queue.ui.highlightFormItems,
  appeal: state.queue.pendingChanges.appeals[ownProps.vacolsId],
  issue: state.queue.pendingChanges.editingIssue
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateAppealIssue,
  startEditingAppealIssue,
  cancelEditingAppealIssue,
  saveEditedAppealIssue
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(AddEditIssueView));
