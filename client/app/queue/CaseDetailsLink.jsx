import _ from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import COPY from '../../COPY.json';
import { subHeadTextStyle } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { setActiveAppeal, setActiveTask } from './CaseDetail/CaseDetailActions';

const getLinkText = (appeal) => <React.Fragment>{appeal.veteran_full_name} ({appeal.vbms_id})</React.Fragment>;

class CaseDetailsLink extends React.PureComponent {
  setActiveAppealAndTask = () => {
    this.props.setActiveAppeal(this.props.appeal);
    this.props.setActiveTask(this.props.task);
  }

  render() {
    const {
      appeal: { attributes: appeal },
      disabled
    } = this.props;

    return <React.Fragment>
      <Link
        to={`/queue/appeals/${appeal.vacols_id}`}
        disabled={disabled}
        onClick={this.props.onClick || this.setActiveAppealAndTask}>
        {this.props.getLinkText(appeal)}
      </Link>
      {!_.isNull(_.get(appeal, 'appellant_full_name')) && <React.Fragment>
        <br />
        <span {...subHeadTextStyle}>{COPY.CASE_DIFF_VETERAN_AND_APPELLANT}</span>
      </React.Fragment>}
      {appeal.paper_case && <React.Fragment>
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
