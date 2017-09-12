import React from 'react';
import PropTypes from 'prop-types';
import Checkbox from '../../components/Checkbox';


class HearingWorksheetSingleIssue extends React.Component {

  render() {
    let { issue } = this.props;

    return <div>
          <Checkbox label="Re-Open" name={`${issue.id}-chk_reopen`}
            onChange={this.props.onToggleReopen} value={issue.reopen}>
          </Checkbox>
          <Checkbox label="Allow" name={`${issue.id}-chk_allow`}
            onChange={this.props.onToggleAllow} value={issue.allow}>
          </Checkbox>
          <Checkbox label="Deny" name={`${issue.id}-chk_deny`}
            onChange={this.props.onToggleDeny} value={issue.deny}>
          </Checkbox>
          <Checkbox label="Remand" name={`${issue.id}-chk_remand`}
            onChange={this.props.onToggleRemand} value={issue.remand}>
          </Checkbox>
          <Checkbox label="Dismiss" name={`${issue.id}-chk_dismiss`}
            onChange={this.props.onToggleDismiss} value={issue.dismiss}>
          </Checkbox>
          <Checkbox label="VHA" name={`${issue.id}-chk_vha`}
            onChange={this.props.onToggleVHA} value={issue.vha}>
          </Checkbox>
        </div>;
  }
}

HearingWorksheetSingleIssue.propTypes = {
  issue: PropTypes.object.isRequired
};

export default HearingWorksheetSingleIssue;

