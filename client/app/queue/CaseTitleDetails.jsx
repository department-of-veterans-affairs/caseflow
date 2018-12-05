import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';

import {
  actionableTasksForAppeal,
  appealWithDetailSelector
} from './selectors';
import DocketTypeBadge from './components/DocketTypeBadge';
import CopyTextButton from '../components/CopyTextButton';
import ReaderLink from './ReaderLink';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import COPY from '../../COPY.json';
import { COLORS } from '../constants/AppConstants';
import { renderLegacyAppealType } from './utils';

const editButton = css({
  float: 'right'
});

const containingDivStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  display: 'block',
  padding: '0 0 1.5rem 4rem',

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
  ':not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  ':not(:first-child)': { paddingLeft: '1.5rem' },

  '& > h4': { textTransform: 'uppercase' }
});

const CaseTitleScaffolding = (props) => <div {...containingDivStyling}>
  <ul {...listStyling}>
    {props.children.map((child, i) => child && <li key={i} {...listItemStyling}>{child}</li>)}
  </ul>
</div>;

export class CaseTitleDetails extends React.PureComponent {
  render = () => {
    const {
      appeal,
      appealId,
      redirectUrl,
      taskType,
      primaryTask
    } = this.props;

    // TODO: Replace this with userIsVsoEmployee (see case title)
    const taskAssignedToVso = primaryTask && primaryTask.assignedTo.type === 'Vso';

    return <CaseTitleScaffolding>
      <React.Fragment>
        <h4>{COPY.CASE_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL}</h4>
        <div><DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />{appeal.docketNumber}</div>
      </React.Fragment>

      { !taskAssignedToVso &&
        <React.Fragment>
          <h4>Veteran Documents</h4>
          <div>
            <ReaderLink
              appealId={appealId}
              analyticsSource="queue_task"
              redirectUrl={redirectUrl}
              appeal={appeal}
              taskType={taskType}
              longMessage />
          </div>
        </React.Fragment> }

      <React.Fragment>
        <h4>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TYPE_LABEL}</h4>
        <div>
          {renderLegacyAppealType({
            aod: appeal.isAdvancedOnDocket,
            type: appeal.caseType
          })}
          {!appeal.isLegacyAppeal && this.props.canEditAod && <span {...editButton}>
            <Link
              to={`/queue/appeals/${appeal.externalId}/modal/advanced_on_docket_motion`}>
              Edit
            </Link>
          </span>}
        </div>
      </React.Fragment>

      { !taskAssignedToVso && primaryTask && primaryTask.documentId &&
        <React.Fragment>
          <h4>{COPY.CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}</h4>
          <div><CopyTextButton text={primaryTask.documentId}/></div>
        </React.Fragment> }
    </CaseTitleScaffolding>;
  };
}

const mapStateToProps = (state, ownProps) => {
  const { featureToggles, userRole, canEditAod } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    featureToggles,
    userRole,
    primaryTask: actionableTasksForAppeal(state, { appealId: ownProps.appealId })[0],
    canEditAod
  };
};

export default connect(mapStateToProps)(CaseTitleDetails);
