// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import classNames from 'classnames';

import {
  setDecisionOptions,
  resetDecisionOptions,
  deleteAppeal
} from './QueueActions';
import {
  setSelectingJudge,
  requestSave
} from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import RadioField from '../components/RadioField';
import Checkbox from '../components/Checkbox';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import Button from '../components/Button';
import Alert from '../components/Alert';

import {
  fullWidth,
  marginBottom,
  marginTop,
  ATTORNEY_COMMENTS_MAX_LENGTH,
  DOCUMENT_ID_MAX_LENGTH,
  OMO_ATTORNEY_CASE_REVIEW_WORK_PRODUCT_TYPES,
  ISSUE_DISPOSITIONS
} from './constants';
import SearchableDropdown from '../components/SearchableDropdown';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';
import COPY from '../../COPY.json';

const radioFieldStyling = css(marginBottom(0), marginTop(2), {
  '& .question-label': marginBottom(0)
});
const selectJudgeButtonStyling = (selectedJudge) => css({ paddingLeft: selectedJudge ? '' : 0 });

import type {
  Task,
  LegacyAppeal,
  Judges
} from './types/models';
import type { UiStateError } from './types/state';

type Params = {|
  appealId: string,
  nextStep: string
|};

type Props = Params & {|
  // state
  appeal: LegacyAppeal,
  decision: Object,
  task: Task,
  judges: Judges,
  highlightFormItems: Boolean,
  userRole: string,
  selectingJudge: Boolean,
  error: ?UiStateError,
  // dispatch
  setDecisionOptions: typeof setDecisionOptions,
  resetDecisionOptions: typeof resetDecisionOptions,
  setSelectingJudge: typeof setSelectingJudge,
  requestSave: typeof requestSave,
  deleteAppeal: typeof deleteAppeal
|};

class SubmitDecisionView extends React.PureComponent<Props> {
  componentDidMount = () => {
    if (!_.isEmpty(this.props.judges)) {
      return Promise.resolve();
    } 
  }
    const { task: { attributes: task } } = this.props;
    const judge = this.props.judges[task.added_by_css_id];

    if (judge) {
      this.props.setDecisionOptions({
        judge: {
          label: task.added_by_name,
          value: judge.id
        }
      });
    }
  };

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

    if (selectingJudge) {
      componentContent = <React.Fragment>
        <SearchableDropdown
          name="Select a judge"
          placeholder="Select a judge&hellip;"
          options={_.map(judges, (judge, value) => ({
            label: judge.full_name,
            value
          }))}
          onChange={({ value }) => {
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

const mapStateToProps = (state, ownProps) => {
  const {
    queue: {
      judges
    },
    ui: {
      highlightFormItems,
      selectingJudge
    }
  } = state;

  return {
    judges,
    highlightFormItems,
    selectingJudge
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions,
  resetDecisionOptions,
  setSelectingJudge,
  requestSave,
  deleteAppeal
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(
  decisionViewBase(SubmitDecisionView)
): React.ComponentType<Params>
);
