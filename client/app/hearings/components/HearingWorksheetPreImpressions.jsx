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
    this.props.onToggleReopen(reopen, this.props.issue.id);
  onToggleAllow = (allow) =>
    this.props.onToggleAllow(allow, this.props.issue.id);
  onToggleDeny = (deny) =>
    this.props.onToggleDeny(deny, this.props.issue.id);
  onToggleRemand = (remand) =>
    this.props.onToggleRemand(remand, this.props.issue.id);
  onToggleDismiss = (dismiss) =>
    this.props.onToggleDismiss(dismiss, this.props.issue.id);
  onToggleVHA = (vha) =>
    this.props.onToggleVHA(vha, this.props.issue.id);

  render() {
    let { issue } = this.props;

    return <div className="cf-hearings-worksheet-actions">
      <Checkbox label="Re-Open" name={`${issue.id}-${issue.appeal_id}-chk_reopen`}
        onChange={this.onToggleReopen} value={issue.reopen} />
      <Checkbox label="Allow" name={`${issue.id}-${issue.appeal_id}-chk_allow`}
        onChange={this.onToggleAllow} value={issue.allow} />
      <Checkbox label="Deny" name={`${issue.id}-${issue.appeal_id}-chk_deny`}
        onChange={this.onToggleDeny} value={issue.deny} />
      <Checkbox label="Remand" name={`${issue.id}-${issue.appeal_id}-chk_remand`}
        onChange={this.onToggleRemand} value={issue.remand} />
      <Checkbox label="Dismiss" name={`${issue.id}-${issue.appeal_id}-chk_dismiss`}
        onChange={this.onToggleDismiss} value={issue.dismiss} />
      <Checkbox label="VHA" name={`${issue.id}-${issue.appeal_id}-chk_vha`}
        onChange={this.onToggleVHA} value={issue.vha} />
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

