import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class ReaderLink extends React.PureComponent {
  render = () => {
    const {
      docCount,
      vacols_id: vacolsId
    } = this.props;

    return <Link href={`/reader/appeal/${vacolsId}/documents`}>
      {docCount ? `View ${docCount.toLocaleString()} in Reader` : 'View in Reader'}
    </Link>;
  };
}

ReaderLink.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) =>
  _.pick(state.queue.loadedQueue.appeals[ownProps.appealId].attributes, 'docCount', 'vacols_id');

export default connect(mapStateToProps)(ReaderLink);
