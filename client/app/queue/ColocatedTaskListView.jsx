import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import QueueTableBuilder from './QueueTableBuilder';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { hideSuccessMessage } from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import {
  marginBottom
} from './constants';

import Alert from '../components/Alert';

const containerStyles = css({
  position: 'relative'
});

export class ColocatedTaskListView extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  };

  componentWillUnmount = () => this.props.hideSuccessMessage();

  render = () => {
    const { success } = this.props;

    return <AppSegment filledBackground styling={containerStyles}>
      {success && <Alert type="success" title={success.title} message={success.detail} styling={marginBottom(1)} />}
      <QueueTableBuilder />
    </AppSegment>;
  };
}

const mapStateToProps = (state) => {
  const { success } = state.ui.messages;

  return {
    success
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseSelectSearch,
  hideSuccessMessage
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(ColocatedTaskListView));

ColocatedTaskListView.propTypes = {
  clearCaseSelectSearch: PropTypes.func,
  hideSuccessMessage: PropTypes.func,
  success: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  })
};
