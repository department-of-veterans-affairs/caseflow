import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import Checkbox from '../../../components/Checkbox';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import {
  onToggleReopen, onToggleAllow, onToggleDeny,
  onToggleRemand, onToggleDismiss, onToggleOMO
} from '../../actions/hearingWorksheetActions';

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
  onToggleOMO = (omo) =>
    this.props.onToggleOMO(omo, this.props.issue.id);

  render() {
    let { issue, print, ama } = this.props;

    return <div className="cf-hearings-worksheet-issues">
      <Checkbox label="Re-Open" name={`${issue.id}-${issue.appeal_id || issue.decision_review_id}-chk_reopen`}
        onChange={this.onToggleReopen} value={issue.reopen} disabled={print} />
      <Checkbox label="Allow" name={`${issue.id}-${issue.appeal_id || issue.decision_review_id}-chk_allow`}
        onChange={this.onToggleAllow} value={issue.allow} disabled={print} />
      <Checkbox label="Deny" name={`${issue.id}-${issue.appeal_id || issue.decision_review_id}-chk_deny`}
        onChange={this.onToggleDeny} value={issue.deny} disabled={print} />
      <Checkbox label="Remand" name={`${issue.id}-${issue.appeal_id || issue.decision_review_id}-chk_remand`}
        onChange={this.onToggleRemand} value={issue.remand} disabled={print} />
      <Checkbox label="Dismiss" name={`${issue.id}-${issue.appeal_id || issue.decision_review_id}-chk_dismiss`}
        onChange={this.onToggleDismiss} value={issue.dismiss} disabled={print} />
      { !ama && <Checkbox label="OMO" name={`${issue.id}-${issue.appeal_id || issue.decision_review_id}-chk_omo`}
        onChange={this.onToggleOMO} value={issue.omo} disabled={print} /> }
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onToggleReopen,
  onToggleAllow,
  onToggleDeny,
  onToggleRemand,
  onToggleDismiss,
  onToggleOMO
}, dispatch);

const mapStateToProps = (state) => ({
  HearingWorksheetPreImpressions: state
});

HearingWorksheetPreImpressions.propTypes = {
  issue: PropTypes.object.isRequired,
  print: PropTypes.bool,
  ama: PropTypes.bool
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetPreImpressions);
