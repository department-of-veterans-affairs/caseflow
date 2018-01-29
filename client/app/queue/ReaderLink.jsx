import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class ReaderLink extends React.PureComponent {
  render = () => <Link href={`/reader/appeal/${this.props.appeal.attributes.vacols_id}/documents`}>
    {this.props.text || _.get(this.props.appeal, this.props.displayAttr).toLocaleString()}
  </Link>;
}

ReaderLink.propTypes = {
  appealId: PropTypes.string.isRequired,
  displayAttr: PropTypes.string,
  text: PropTypes.string
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.appealId]
});

export default connect(mapStateToProps)(ReaderLink);
