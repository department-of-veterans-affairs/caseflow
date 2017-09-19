import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import Checkbox from '../../components/Checkbox';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import {
  onToggleReopen, onToggleAllow, onToggleDeny,
  onToggleRemand, onToggleDismiss, onToggleVHA
       } from '../actions/Issue';

class HearingWorksheetPreImpressions extends PureComponent {

  onToggleReopen = (reopen) =>
    this.props.onToggleReopen(reopen, this.props.issue.id, this.props.appeal.id);
  onToggleAllow = (allow) =>
    this.props.onToggleAllow(allow, this.props.issue.id, this.props.appeal.id);
  onToggleDeny = (deny) =>
    this.props.onToggleDeny(deny, this.props.issue.id, this.props.appeal.id);
  onToggleRemand = (remand) =>
    this.props.onToggleRemand(remand, this.props.issue.id, this.props.appeal.id);
  onToggleDismiss = (dismiss) =>
    this.props.onToggleDismiss(dismiss, this.props.issue.id, this.props.appeal.id);
  onToggleVHA = (vha) =>
    this.props.onToggleVHA(vha, this.props.issue.id, this.props.appeal.id);

  render() {
    let { issue } = this.props;

    return <div className="cf-hearings-worksheet-actions">
            <Checkbox label="Re-Open" name={`${issue.id}-chk_reopen`}
              onChange={this.onToggleReopen} value={issue.reopen}>
            </Checkbox>
            <Checkbox label="Allow" name={`${issue.id}-chk_allow`}
              onChange={this.onToggleAllow} value={issue.allow}>
            </Checkbox>
            <Checkbox label="Deny" name={`${issue.id}-chk_deny`}
              onChange={this.onToggleDeny} value={issue.deny}>
            </Checkbox>
            <Checkbox label="Remand" name={`${issue.id}-chk_remand`}
              onChange={this.onToggleRemand} value={issue.remand}>
            </Checkbox>
            <Checkbox label="Dismiss" name={`${issue.id}-chk_dismiss`}
              onChange={this.onToggleDismiss} value={issue.dismiss}>
            </Checkbox>
            <Checkbox label="VHA" name={`${issue.id}-chk_vha`}
              onChange={this.onToggleVHA} value={issue.vha}>
            </Checkbox>
        </div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onToggleReopen,
  onToggleAllow,
  onToggleDeny,
  onToggleRemand,
  onToggleDismiss,
  onToggleVHA
}, dispatch);

const mapStateToProps = (state) => ({
  HearingWorksheetPreImpressions: state
});

HearingWorksheetPreImpressions.propTypes = {
  issue: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetPreImpressions);

