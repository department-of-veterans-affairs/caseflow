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

    return <Link href={`/reader/appeal/${vacolsId}/documents`}>
      {linkText}
    </Link>;
  };
}

ReaderLink.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) =>
  _.pick(state.queue.loadedQueue.appeals[ownProps.appealId].attributes, 'docCount', 'vacols_id');

export default connect(mapStateToProps)(ReaderLink);
