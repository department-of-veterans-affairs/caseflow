import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { setSpecialIssues } from './QueueActions';
import { requestSave } from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import Alert from '../components/Alert';
import Checkbox from '../components/Checkbox';
import SPECIAL_ISSUES from '../constants/SpecialIssues';
import COPY from '../../COPY.json';
import ApiUtil from '../util/ApiUtil';

class SelectSpecialIssuesView extends React.PureComponent {
  getPageName = () => COPY.SPECIAL_ISSUES_PAGE_TITLE;

  onChangeSpecialIssue = (issue) => (value) => {
    this.props.setSpecialIssues({
      [issue.snakeCase]: value
    });
  }

  goToNextStep = () => {
    const {
      appeal,
      specialIssues
    } = this.props;

    const data = ApiUtil.convertToSnakeCase({ specialIssues });

    this.props.requestSave(`/appeals/${appeal.externalId}/special_issues`, { data }, null);
  };

  render = () => {
    const {
      specialIssues,
      error
    } = this.props;

    const specialIssueCheckboxes = SPECIAL_ISSUES.map((issue) => {
      if (issue.nonCompensation) {
        return null;
      }

      return <Checkbox
        key={issue.specialIssue}
        label={issue.display}
        name={issue.specialIssue}
        value={specialIssues[issue.snakeCase]}
        onChange={this.onChangeSpecialIssue(issue)}
      />;
    });

    return <React.Fragment>
      <h1>
        {this.getPageName()}
      </h1>
      {error && <Alert type="error" title={error.title} message={error.detail} />}
      <div className="cf-multiple-columns">
        {specialIssueCheckboxes}
      </div>
    </React.Fragment>;
  };
}

SelectSpecialIssuesView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  specialIssues: state.queue.specialIssues,
  error: state.ui.messages.error
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setSpecialIssues,
  requestSave
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SelectSpecialIssuesView));
