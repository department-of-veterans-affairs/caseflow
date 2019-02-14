import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../util/ApiUtil';
import _ from 'lodash';

import { loadAppealDocCount, setAppealDocCount, errorFetchingDocumentCount } from './QueueActions';

import { css } from 'glamor';
import { COLORS } from '../constants/AppConstants';

const documentCountStyling = css({
  color: COLORS.GREY
});

class AppealDocumentCount extends React.PureComponent {
  componentDidMount = () => {
    const {
      appeal,
      cached,
      docCountForAppeal
    } = this.props;

    if (appeal.isPaperCase) {
      return;
    }

    if (docCountForAppeal &&
      (_.isNumber(docCountForAppeal.precise) || (cached && _.isNumber(docCountForAppeal.cached)))) {
      return;
    }

    const requestOptions = {
      withCredentials: true,
      timeout: { response: 5 * 60 * 1000 }
    };

    const endpoint = `document_count${cached ? '?cached' : ''}`;

    this.props.loadAppealDocCount(this.props.externalId);

    ApiUtil.get(`/appeals/${this.props.externalId}/${endpoint}`, requestOptions).then((response) => {
      const resp = JSON.parse(response.text);

      this.props.setAppealDocCount(this.props.externalId, resp.document_count, Boolean(cached));
    }, () => {
      this.props.errorFetchingDocumentCount(this.props.externalId);
    });
  }

  render = () => {
    const {
      docCountForAppeal,
      cached,
      loadingText
    } = this.props;

    if (docCountForAppeal) {
      if (_.isNumber(docCountForAppeal.precise)) {
        return docCountForAppeal.precise;
      } else if (cached && _.isNumber(docCountForAppeal.cached)) {
        return docCountForAppeal.cached;
      } else if (docCountForAppeal.error) {
        return docCountForAppeal.error;
      } else if (loadingText && docCountForAppeal.loading) {
        return <span {...documentCountStyling}>Loading number of docs...</span>;
      }
    }

    return null;
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
  loadAppealDocCount,
  setAppealDocCount,
  errorFetchingDocumentCount
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AppealDocumentCount);
