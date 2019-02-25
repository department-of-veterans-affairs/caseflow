import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import classNames from 'classnames';

import {
  setDecisionOptions,
  fetchJudges
} from './QueueActions';
import { setSelectingJudge } from './uiReducer/uiActions';

import Button from '../components/Button';
import SearchableDropdown from '../components/SearchableDropdown';
import COPY from '../../COPY.json';

const selectJudgeButtonStyling = (selectedJudge) => css({ paddingLeft: selectedJudge ? '' : 0 });

class JudgeSelectComponent extends React.PureComponent {
  componentDidMount = () => {
    if (_.isEmpty(this.props.judges)) {
      this.props.fetchJudges();
    } else {
      this.setDefaultJudge(this.props.judges);
    }
  }

  setDefaultJudge = (judges) => {
    const judge =
       _.find(judges, { css_id: this.props.judgeSelector }) ||
       _.find(judges, { id: this.props.judgeSelector });

    if (judge) {
      this.props.setDecisionOptions({
        reviewing_judge_id: judge.id
      });
    }
  };

  componentWillReceiveProps = (nextProps) => {
    if (nextProps.judges !== this.props.judges) {
      this.setDefaultJudge(nextProps.judges);
    }
  }

  render = () => {
    const {
      selectingJudge,
      judges,
      decision: { opts: decisionOpts },
      highlightFormItems
    } = this.props;
    let componentContent = <span />;
    const selectedJudge = _.get(this.props.judges, decisionOpts.reviewing_judge_id);
    const shouldDisplayError = highlightFormItems && !selectedJudge;
    const fieldClasses = classNames({
      'usa-input-error': shouldDisplayError
    });
    const judgeOptions = _.map(judges, (judge, value) => ({
      label: judge.full_name,
      value
    }));

    if (judgeOptions.length === 0) {
      componentContent = <React.Fragment>Loading judges&hellip;</React.Fragment>;
    } else if (selectingJudge) {
      componentContent = <React.Fragment>
        <SearchableDropdown
          name="Select a judge"
          placeholder="Select a judge&hellip;"
          options={judgeOptions}
          onChange={(option) => {
            if (!option) {
              return;
            }
            const { value } = option;

            this.props.setSelectingJudge(false);
            this.props.setDecisionOptions({ reviewing_judge_id: value });
          }}
          hideLabel />
      </React.Fragment>;
    } else {
      componentContent = <React.Fragment>
        {selectedJudge && <span>{selectedJudge.full_name}</span>}
        <Button
          id="select-judge"
          linkStyling
          willNeverBeLoading
          styling={selectJudgeButtonStyling(selectedJudge)}
          onClick={() => this.props.setSelectingJudge(true)}>
            Select {selectedJudge ? 'another' : 'a'} judge
        </Button>
      </React.Fragment>;
    }

    return <div className={fieldClasses}>
      <label>Submit to judge:</label>
      {shouldDisplayError && <span className="usa-input-error-message">
        {COPY.FORM_ERROR_FIELD_REQUIRED}
      </span>}
      {componentContent}
    </div>;
  };
}

const mapStateToProps = (state) => {
  const {
    queue: {
      judges,
      stagedChanges: {
        taskDecision: decision
      }
    },
    ui: {
      highlightFormItems,
      selectingJudge
    }
  } = state;

  return {
    judges,
    decision,
    highlightFormItems,
    selectingJudge
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions,
  setSelectingJudge,
  fetchJudges
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(JudgeSelectComponent));
