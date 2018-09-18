import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../util/ApiUtil';
import _ from 'lodash';

import { setAppealDocCount } from './QueueActions';

import { css } from 'glamor';
import { COLORS } from '../constants/AppConstants';

const documentCountStyling = css({
  color: COLORS.GREY
});

class AppealDocumentCount extends React.PureComponent {
  componentDidMount = () => {
    const appeal = this.props.appeal;

    if (appeal.isPaperCase) {
      return;
    }

    if (!this.props.docCountForAppeal) {
      const requestOptions = {
        withCredentials: true,
        timeout: true
      };

      ApiUtil.get(`/appeals/${this.props.externalId}/document_count`, requestOptions).then((response) => {
        const resp = JSON.parse(response.text);

        this.props.setAppealDocCount(this.props.externalId, resp.document_count);
      });
    }
  }

  render = () => {
    if (_.isNil(this.props.docCountForAppeal)) {
      if (this.props.loadingText) {
        return <span {...documentCountStyling}>Loading number of docs...</span>;
      }

      return null;
    }

    return <span {...documentCountStyling}>
      {`${this.props.docCountForAppeal} docs`}
    </span>;
  }
}

AppealDocumentCount.propTypes = {
  appeal: PropTypes.object.isRequired,
  loadingText: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  const externalId = ownProps.appeal.externalId;

  return {
    externalId,
    docCountForAppeal: state.queue.docCountForAppeal[externalId] || null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setAppealDocCount
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AppealDocumentCount);
