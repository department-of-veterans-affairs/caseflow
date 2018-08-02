import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import COPY from '../../COPY.json';
import { subHeadTextStyle } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { setActiveAppeal, setActiveTask } from './CaseDetail/CaseDetailActions';

const getLinkText = (appeal) => <React.Fragment>{appeal.veteranName} ({appeal.veteranFileNumber})</React.Fragment>;

class CaseDetailsLink extends React.PureComponent {
  render() {
    const {
      appeal,
      disabled
    } = this.props;

    return <React.Fragment>
      <Link
        to={`/queue/appeals/${appeal.externalId}`}
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

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setActiveAppeal,
  setActiveTask
}, dispatch);

export default connect(null, mapDispatchToProps)(CaseDetailsLink);
