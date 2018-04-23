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

const CaseDetailsLink = (props) => {
  return <React.Fragment>
    {!props.task.attributes.task_id && <WarningSymbol />}
    <Link to={`/tasks/${props.task.vacolsId}`} disabled={!props.task.attributes.task_id}>
      {props.appeal.attributes.veteran_full_name} ({props.appeal.attributes.vbms_id})
    </Link>
    {!_.isNull(_.get(props.appeal.attributes, 'appellant_full_name')) && <React.Fragment>
      <br />
      <span {...subHeadStyle}>Veteran is not the appellant</span>
    </React.Fragment>}
  </React.Fragment>;
};

CaseDetailsLink.propTypes = {
  task: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired
};

export default CaseDetailsLink;
