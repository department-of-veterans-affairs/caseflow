import React from 'react';
import { NewFileIcon } from '../components/RenderFunctions';

export default class NewFile extends React.PureComponent {

  componentDidMount = () => {

  }

  render = () => {
    if (appeal.hasNewFiles) {
      return <NewFileIcon />;
    } else {
      return null
    }
  }
}

NewFile.propTypes = {
  appeal: PropTypes.shape({
    hasNewFiles: PropTypes.bool
  }).isRequired,
};

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.stagedChanges.appeals[ownProps.appealId];
  const issues = appeal.attributes.issues;

  return {
    appeal,
    issues: _.filter(issues, (issue) => issue.disposition === ISSUE_DISPOSITIONS.REMANDED),
    issue: _.find(issues, (issue) => issue.vacols_sequence_id === ownProps.issueId),
    highlight: state.ui.highlightFormItems
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  startEditingAppealIssue,
  saveEditedAppealIssue
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(NewFile);
