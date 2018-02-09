import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { TASK_ACTIONS } from './constants';
class ReaderLink extends React.PureComponent {

  readerLinkAnalytics = () => {
    window.analyticsEvent(this.props.analyticsSource, TASK_ACTIONS.QUEUE_TO_READER);
  }

  render = () => {
    const {
      docCount,
      message,
      vacols_id: vacolsId
    } = this.props;

    let linkText = 'View in Reader';

    if (message) {
      linkText = message;
    } else if (!_.isUndefined(docCount)) {
      linkText = `View ${docCount.toLocaleString()} in Reader`;
    }

    return <Link href={`/reader/appeal/${vacolsId}/documents`} onClick={this.readerLinkAnalytics}>
      {linkText}
    </Link>;
  };
}

ReaderLink.propTypes = {
  analyticsSource: PropTypes.string,
  interactionType: PropTypes.string,
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) =>
  _.pick(state.queue.loadedQueue.appeals[ownProps.vacolsId].attributes, 'docCount', 'vacols_id');

export default connect(mapStateToProps)(ReaderLink);
