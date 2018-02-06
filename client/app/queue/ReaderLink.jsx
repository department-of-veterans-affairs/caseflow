import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class ReaderLink extends React.PureComponent {
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

    const url = encodeURIComponent('/queue')

    return <Link href={`/reader/appeal/${vacolsId}/documents?queue_redirect_url=${url}`}>
      {linkText}
    </Link>;
  };
}

ReaderLink.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) =>
  _.pick(state.queue.loadedQueue.appeals[ownProps.vacolsId].attributes, 'docCount', 'vacols_id');

export default connect(mapStateToProps)(ReaderLink);
