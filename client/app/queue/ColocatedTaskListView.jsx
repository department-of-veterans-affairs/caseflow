// @flow
import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import StatusMessage from '../components/StatusMessage';
import AmaTaskTable from './components/AmaTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../components/Alert';

import {
  appealsByAssigneeCssIdSelector,
  tasksByAssigneeCssIdSelector,
  amaTasksByAssigneeId
} from './selectors';
import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState,
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';
import type { LegacyAppeals, AmaTask } from './types/models';
import type { State, UiStateError } from './types/state';

type Params = {|
  userId: number,
  error: ?UiStateError,
  success: string
|};

type Props = Params & {|
  // From state
  amaTasks: Array<AmaTask>,
  // Action creators
  clearCaseSelectSearch: typeof clearCaseSelectSearch,
  resetErrorMessages: typeof resetErrorMessages,
  resetSuccessMessages: typeof resetSuccessMessages,
  resetSaveState: typeof resetSaveState,
|};

class ColocatedTaskListView extends React.PureComponent<Props> {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  };

  render = () => {
    const { error, success } = this.props;
    const tableContent = <div>
      <h1 {...fullWidth}></h1>
      {error && <Alert type="error" title={error.title} scrollOnAlert={false}>
        {error.detail}
      </Alert>}
      {success && <Alert type="success" title={success} scrollOnAlert={false}>
      </Alert>}
      <AmaTaskTable tasks={this.props.amaTasks} />
    </div>;

    return <AppSegment filledBackground>
      {tableContent}
    </AppSegment>;
  };
}

ColocatedTaskListView.propTypes = {
};

const mapStateToProps = (state: State, ownProps: Params) => {
  const {
    queue: {
      stagedChanges: {
        taskDecision
      },
      judges
    },
    ui: {
      messages: {
        error,
        success
      }
    }
  } = state;

  return {
    amaTasks: amaTasksByAssigneeId(state)[ownProps.userId],
    error,
    success,
    taskDecision,
    judges
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState
  }, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(ColocatedTaskListView): React.ComponentType<Params>);
