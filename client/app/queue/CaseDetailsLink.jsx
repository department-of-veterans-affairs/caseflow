import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import { COLORS as COMMON_COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { WarningSymbol } from '../components/RenderFunctions';

const subHeadStyle = css({
  fontSize: 'small',
  color: COMMON_COLORS.GREY_MEDIUM
});

class CaseDetailsLink extends React.PureComponent {

  render = () => {
    console.log(this.props.task, this.props.appeal);
    return <React.Fragment>
      {!this.props.task.attributes.task_id && <WarningSymbol />}
      <Link to={`/tasks/${this.props.task.vacolsId}`} disabled={!this.props.task.attributes.task_id}>
        {this.props.appeal.attributes.veteran_full_name} ({this.props.appeal.attributes.vbms_id})
      </Link>
      {!_.isNull(this.props.appeal) && <React.Fragment>
        <br />
        <span {...subHeadStyle}>Veteran is not the appellant</span>
      </React.Fragment>}
    </React.Fragment>;
  };
}

CaseDetailsLink.propTypes = {
  task: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired
};

export default CaseDetailsLink;
