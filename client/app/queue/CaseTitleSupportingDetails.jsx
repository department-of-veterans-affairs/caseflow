import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';

import {
  actionableTasksForAppeal,
  appealWithDetailSelector
} from './selectors';
import DocketTypeBadge from './../components/DocketTypeBadge';
import CopyTextButton from '../components/CopyTextButton';
import ReaderLink from './ReaderLink';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import COPY from '../../COPY.json';
import { COLORS } from '../constants/AppConstants';
import { renderLegacyAppealType } from './utils';

const editButton = css({
  float: 'right',
  marginLeft: '0.5rem'
});

const containingDivStyling = css({
  backgroundColor: COLORS.WHITE,
  display: 'block',
  padding: '0 0 0 2rem',

  '& > *': {
    display: 'inline-block',
    margin: '0'
  }
});

const listStyling = css({
  listStyleType: 'none',
  verticalAlign: 'super',
  padding: '1rem 0 0 0'
});

const listItemStyling = css({
  display: 'inline',
  float: 'left',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':not(:first-child)': {
    '& > div': {
      borderLeft: `1px solid ${COLORS.GREY_LIGHT}`
    },
    '& > *': {
      paddingLeft: '1.5rem'
    }
  },
  '& > h4': { textTransform: 'uppercase' }
});

const docketBadgeContainerStyle = css({
  border: '1px',
  borderStyle: 'solid',
  borderColor: COLORS.GREY_LIGHT,
  padding: '0.5rem 1rem 0.5rem 0.5rem',
  backgroundColor: COLORS.WHITE
});

const CaseSupportingDetailTitleScaffolding = (props) => <div {...containingDivStyling}>
  <ul {...listStyling}>
    {props.children.map((child, i) => child && <li key={i} {...listItemStyling}>{child}</li>)}
  </ul>
</div>;

export class CaseTitleSupportingDetails extends React.PureComponent {
  render = () => {
    const {
      appeal,
      appealId,
      redirectUrl,
      taskType,
      primaryTask,
      userIsVsoEmployee
    } = this.props;
    console.log(appeal)
    console.log(this.props)

    return <CaseSupportingDetailTitleScaffolding>
      <React.Fragment>
        <h4>{COPY.TASK_SNAPSHOT_ASSIGNED_JUDGE_LABEL}</h4>
        <div>
          {appeal.assignedJudge ? appeal.assignedJudge.full_name : ' '}
        </div>
      </React.Fragment>

      <React.Fragment>
        <h4>{COPY.TASK_SNAPSHOT_ASSIGNED_ATTORNEY_LABEL}</h4>
        <div>
           {appeal.assignedAttorney ? appeal.assignedAttorney.full_name : ' '}
        </div>
      </React.Fragment>

      { appeal.veteranFullName !== appeal.appellantFullName && <React.Fragment>
        <h4>{COPY.CASE_DETAILS_VET_NOT_APELLANT}</h4>
          <div>
            {COPY.CASE_DETAILS_PAPER_CASE}
          </div>
        </React.Fragment> }

    </CaseSupportingDetailTitleScaffolding>;
  };
}

const mapStateToProps = (state, ownProps) => {
  const { featureToggles, userRole, canEditAod } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    featureToggles,
    userRole,
    primaryTask: actionableTasksForAppeal(state, { appealId: ownProps.appealId })[0],
    canEditAod,
    userIsVsoEmployee: state.ui.userIsVsoEmployee
  };
};

export default connect(mapStateToProps)(CaseTitleSupportingDetails);
