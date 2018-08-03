// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AmaTaskTable from './components/AmaTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  amaTasksByAssigneeId
} from './selectors';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import type { AmaTask } from './types/models';
import type { State } from './types/state';

type Params = {|
  userId: number
|};

type Props = Params & {|
  // From state
  amaTasks: Array<AmaTask>,
  // Action creators
  clearCaseSelectSearch: typeof clearCaseSelectSearch
|};

class ColocatedTaskListView extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  };

  render = () => {
    const tableContent = <div>
      <h1 {...fullWidth}></h1>
      <AmaTaskTable tasks={this.props.amaTasks} />
    </div>;

    return <AppSegment filledBackground>
      {tableContent}
    </AppSegment>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => {
  return {
    amaTasks: amaTasksByAssigneeId(state)[ownProps.userId]
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseSelectSearch
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(ColocatedTaskListView): React.ComponentType<Params>);
