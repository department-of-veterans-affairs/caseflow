import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

import { setSpecialIssues } from './QueueActions';
import { requestSave } from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import IssueList from './components/IssueList';
import SelectIssueDispositionDropdown from './components/SelectIssueDispositionDropdown';
import Checkbox from '../components/Checkbox';
import SPECIAL_ISSUES from '../constants/SpecialIssues'
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

    this.props.requestSave(`/appeals/${appeal.externalId}/special_issues`, { data }, { title: "Special issues saved" });
  };

  render = () => {
    const {
      appeal,
      specialIssues
    } = this.props;

    const specialIssueCheckboxes = SPECIAL_ISSUES.map((issue) => {
      return <Checkbox
        key={issue.specialIssue}
        label={issue.display}
        name={issue.specialIssue}
        value={specialIssues[issue.snakeCase]}
        onChange={this.onChangeSpecialIssue(issue)}
      />
    })

    return <React.Fragment>
      <h1>
        {this.getPageName()}
      </h1>
      <div className="cf-multiple-columns">
        {specialIssueCheckboxes}
      </div>
    </React.Fragment>;
  };
}

SelectSpecialIssuesView.propTypes = {
  appealId: PropTypes.string.isRequired,
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  specialIssues: state.queue.specialIssues
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setSpecialIssues,
  requestSave
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SelectSpecialIssuesView));
