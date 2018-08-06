import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';

import COPY from '../../COPY.json';
import { subHeadTextStyle } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const getLinkText = (appeal) => <React.Fragment>{appeal.veteranName} ({appeal.veteranFileNumber})</React.Fragment>;

export default class CaseDetailsLink extends React.PureComponent {
  render() {
    const {
      appeal,
      disabled
    } = this.props;

    return <React.Fragment>
      <Link
        to={`/queue/appeals/${appeal.externalId || appeal.attributes.external_id}`}
        disabled={disabled}
        onClick={this.props.onClick}>
        {this.props.getLinkText(appeal)}
      </Link>
      {appeal.paperCase && <React.Fragment>
        <br />
        <span {...subHeadTextStyle}>{COPY.IS_PAPER_CASE}</span>
      </React.Fragment>}
    </React.Fragment>;
  }
}

CaseDetailsLink.propTypes = {
  task: PropTypes.object,
  appeal: PropTypes.object.isRequired,
  disabled: PropTypes.bool,
  getLinkText: PropTypes.func.isRequired,
  onClick: PropTypes.func
};

CaseDetailsLink.defaultProps = {
  getLinkText
};
