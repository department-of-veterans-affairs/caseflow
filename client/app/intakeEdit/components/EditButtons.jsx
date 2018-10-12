import React from 'react';
import Button from '../../components/Button';
import { connect } from 'react-redux';
import IssueCounter from '../../intake/components/IssueCounter';
import { issueCountSelector } from '../../intake/selectors';

class SaveButtonUnconnected extends React.PureComponent {
  render = () =>
    <Button
      name="submit-update"
    >
      Save
    </Button>;
}

class CancelEditButton extends React.PureComponent {
  render = () => {
    return <Button
      id="cancel-edit"
      linkStyling
      willNeverBeLoading
      onClick={
        () => {
          this.props.history.push('/cancel');
        }
      }
    >
      Cancel edit
    </Button>;
  }
}

const mapStateToProps = (state) => {
  return {
    issueCount: issueCountSelector(state)
  };
};

const IssueCounterConnected = connect(mapStateToProps)(IssueCounter);

export default class EditButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelEditButton />
      <SaveButtonUnconnected history={this.props.history} />
      <IssueCounterConnected />
    </div>
}
