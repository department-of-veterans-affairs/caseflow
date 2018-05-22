import _ from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import COPY from '../../../COPY.json';
import { subHeadTextStyle } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { setActiveAppeal, setActiveTask } from './CaseDetail/CaseDetailActions';

class CaseDetailsLink extends React.PureComponent {
  setActiveAppealAndTask = () => {
    this.props.setActiveAppeal(this.props.appeal);
    this.props.setActiveTask(this.props.task);
  }

  render() {
    const {
      appeal: { attributes: appeal },
      task: { attributes: task },
      disabled
    } = this.props;

    return <React.Fragment>
      <Link
        to={`/queue/appeals/${this.props.task.vacolsId}`}
        disabled={disabled || appeal.paper_case}
        onClick={this.setActiveAppealAndTask}
      >
        {appeal.veteran_full_name} ({appeal.vbms_id})
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
  task: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired,
  disabled: PropTypes.bool
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setActiveAppeal,
  setActiveTask
}, dispatch);

export default connect(null, mapDispatchToProps)(CaseDetailsLink);
