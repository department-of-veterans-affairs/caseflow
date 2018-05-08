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
    return <React.Fragment>
      <Link
        to={`/queue/appeals/${this.props.task.vacolsId}`}
        disabled={!this.props.task.attributes.task_id}
        onClick={this.setActiveAppealAndTask}
      >
        {this.props.appeal.attributes.veteran_full_name} ({this.props.appeal.attributes.vbms_id})
      </Link>
      {!_.isNull(_.get(this.props.appeal.attributes, 'appellant_full_name')) && <React.Fragment>
        <br />
        <span {...subHeadStyle}>Veteran is not the appellant</span>
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
