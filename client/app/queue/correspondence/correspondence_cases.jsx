import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { css } from 'glamor';
import {
  resetErrorMessages,
  resetSuccessMessages
} from '../uiReducer/uiActions';

import TaskTable from '../components/TaskTable';
// import {
//   initialAssignTasksToUser,
//   initialCamoAssignTasksToVhaProgramOffice
// } from '../QueueActions';

class CorrespondenceCasesList extends React.PureComponent {
  // componentDidMount = () => {
  //   this.props.resetSuccessMessages();
  //   this.props.resetErrorMessages();
  // }
  render = () => {
    return <React.Fragment>
      <h1 {...css({ display: 'inline-block' })}>{COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_CORRESPONDENCE_CASES}</h1>
      <div>
        <React.Fragment>
          'maite'
        </React.Fragment>
      </div>
    </React.Fragment>;
  }

}

export default CorrespondenceCasesList;
