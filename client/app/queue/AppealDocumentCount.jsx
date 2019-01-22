import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../util/ApiUtil';
import _ from 'lodash';

import { setAppealDocCount, errorFetchingDocumentCount } from './QueueActions';

import { css } from 'glamor';
import { COLORS } from '../constants/AppConstants';

const documentCountStyling = css({
  color: COLORS.GREY
});

class AppealDocumentCount extends React.PureComponent {
  componentDidMount = () => {
    this.props.setAppealDocCount(this.props.externalId, null);

    const {
      appeal,
      cached
    } = this.props;

    if (appeal.isPaperCase) {
      return;
    }

    const requestOptions = {
      withCredentials: true,
      timeout: { response: 5 * 60 * 1000 }
    };

    const endpoint = `document_count?cached=${cached || false}`;

    ApiUtil.get(`/appeals/${this.props.externalId}/${endpoint}`, requestOptions).then((response) => {
      const resp = JSON.parse(response.text);

      this.props.setAppealDocCount(this.props.externalId, resp.document_count);
    }, (error) => {
      this.props.errorFetchingDocumentCount(this.props.externalId, error);
    });
  }

  render = () => {
    if (_.isNil(this.props.docCountForAppeal)) {
      if (this.props.loadingText) {
        return <span {...documentCountStyling}>Loading number of docs...</span>;
      }

      return null;
    }

    return this.props.docCountForAppeal;
  }
}

AppealDocumentCount.propTypes = {
  appeal: PropTypes.object.isRequired,
  loadingText: PropTypes.bool,
  cached: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  const externalId = ownProps.appeal.externalId;

  return {
    externalId,
    docCountForAppeal: state.queue.docCountForAppeal[externalId] || null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setAppealDocCount,
  errorFetchingDocumentCount
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AppealDocumentCount);
