import { css } from 'glamor';
import _ from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { COLORS as COMMON_COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { setActiveAppeal, setActiveTask } from './CaseDetail/CaseDetailActions';

const subHeadStyle = css({
  fontSize: 'small',
  color: COMMON_COLORS.GREY_MEDIUM
});

class CaseDetailsLink extends React.PureComponent {
  setActiveAppealAndTask = () => {
    this.props.setActiveAppeal(this.props.appeal);
    this.props.setActiveTask(this.props.task);
  }

  render() {
    const {
      appeal: { attributes: appeal },
      task: { attributes: task }
    } = this.props;

    return <React.Fragment>
      <Link
        to={`/queue/appeals/${this.props.task.vacolsId}`}
        disabled={!task.task_id || appeal.paper_case}
        onClick={this.setActiveAppealAndTask}>
        {appeal.veteran_full_name} ({appeal.vbms_id})
      </Link>
      {!_.isNull(_.get(appeal, 'appellant_full_name')) && <React.Fragment>
        <br />
        <span {...subHeadStyle}>Veteran is not the appellant</span>
      </React.Fragment>}
      {appeal.paper_case && <React.Fragment>
        <br />
        <span {...subHeadStyle}>This is a paper case</span>
      </React.Fragment>}
    </React.Fragment>;
  }
}

CaseDetailsLink.propTypes = {
  task: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setActiveAppeal,
  setActiveTask
}, dispatch);

export default connect(null, mapDispatchToProps)(CaseDetailsLink);
