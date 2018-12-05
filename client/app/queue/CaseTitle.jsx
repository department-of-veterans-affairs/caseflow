import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { COLORS } from '../constants/AppConstants';
import ReaderLink from './ReaderLink';
import CopyTextButton from '../components/CopyTextButton';
import { toggleVeteranCaseList } from './uiReducer/uiActions';
import COPY from '../../COPY.json';
import DocketTypeBadge from './components/DocketTypeBadge';
import HearingBadge from './components/HearingBadge';
import SpecialtyCaseBadge from './components/SpecialtyCaseBadge';
import AodBadge from './components/AodBadge';

import { actionableTasksForAppeal } from './selectors';

const containingDivStyling = css({
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  display: 'grid',
  margin: 'auto',
  width: '110%',
  // maxWidth: '110%',
  width: '100%',
  // Offsets the padding from .cf-app-segment--alt to make the bottom border full width.
  // margin: '-2rem -3rem 0 -3rem',
  padding: '0 0 1.5rem 4rem',
  '& > *': {
    display: 'inline-block',
    margin: '0'
  }
});

const ulStyling = css({
  padding: '0 0 0 0',
  margin: '10px 0 0 -25px'
});

const newRow = css({
  margin: '5px 0 0 -18px'
});

const newHeaderStyling = css({
  fontSize: '20px',
  fontWeight: 'bold'
});

const headerSupportStyling = css({
  fontSize: '14px',
  color: 'grey',
  marginLeft: '2px'
});

const listItemStyling = css({
  display: 'inline',
  padding: '0 5px 0 6px',
  fontSize: '14px',
  ':first-child': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` }
});

const spanStyle = css({
  border: '2px',
  borderStyle: 'solid',
  borderColor: '#DCDCDC',
  padding: '5px',
  backgroundColor: 'white'
});

const positionAbsolute = css({
  position: 'absolute',
  margin: '0 0 0 0'
});

const rightMargin = css({
  marginRight: '40px !important'
});

const titleStyle = css({
  fontWeight: 'bold',
  textAlign: 'center',
  fontSize: '10px',
  marginLeft: '10px'
});

const divStyle = css({
  marginRight: '10px'
});

const badgeStyle = css({
  marginRight: '26px',
  marginLeft: '-20px',
  fontSize: '14px'
});
const redType = css({
  color: 'red'
});

const displayNone = css({
  display: 'none'
});

const displayInline = css({
  display: 'inline'
});

const editButton = css({
  margin: '18px 0px 0px 12px',
  position: 'inherit',
  fontSize: '13px'
});

const thStyle = css({
  border: 'none',
  backgroundColor: '#F8F8F8',
  margin: '5px 0 0 20px',
  paddingLeft: '0'
});

const descriptionStyle = css({
  marginLeft: '10px'
});

const caseInfo = css({
  paddingBottom: '50px',
  marginLeft: '10px',
  minHeight: '260px'
});

const caseTitleStyle = css({
  paddingBottom: '50px',
  marginLeft: '-50px',
  width: '100%'
});

class CaseTitle extends React.PureComponent {
  render = () => {
    const {
      appeal,
      primaryTask,
      redirectUrl,
      veteranCaseListIsVisible
    } = this.props;

    return <CaseTitleScaffolding {...caseTitleStyle}>
      <React.Fragment>
        <span {...newHeaderStyling}>{appeal.veteranFullName}</span>
      </React.Fragment>

      <span>
        <span {...headerSupportStyling}> Veteran ID </span>
        <CopyTextButton text={appeal.veteranFileNumber} />
      </span>

      <span {...descriptionStyle} style={{ color: 'red',
        marginLeft: '0px' }}>
        {''}
      </span>

      <React.Fragment>
        <Link onClick={this.props.toggleVeteranCaseList}>
          { veteranCaseListIsVisible ? 'Hide' : 'View' } all cases
        </Link>
      </React.Fragment>

      <span {...badgeStyle}>
        <HearingBadge hearing={appeal.hearings[0]} {...displayInline}
          className={appeal.hearings.length > 0 ? null : displayNone} />
      </span>

      <span className={appeal.isAdvancedOnDocket ? null : displayNone} {...badgeStyle}>
        <AodBadge appeal={appeal} className={displayInline} />
      </span>

      <span className={appeal.isAdvancedOnDocket ? null : displayNone} {...badgeStyle} style={{ paddingLeft: '5px' }}>
        <SpecialtyCaseBadge appeal={appeal.hearings[0]} className={displayInline} />
        {this.props.canEditAod && <span {...editButton}>
          <Link
            to={`/queue/appeals/${appeal.externalId}/modal/advanced_on_docket_motion`}>
            Edit
          </Link>
        </span>}
      </span>

      <br style={{ display: 'block',
        lineHeight: '210%',
        content: '',
        height: '5px',
        visibility: 'hidden',
        marginBottom: '1px' }} />

      <span {...caseInfo}>
        <th {...thStyle}>
          <React.Fragment>
            <span {...titleStyle} className={rightMargin}>
              {COPY.CASE_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL.toUpperCase()}</span><br />
            <span {...spanStyle} {...positionAbsolute}>
              <DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />{appeal.docketNumber}
            </span>
          </React.Fragment>
        </th>

        <th {...thStyle}>
          <React.Fragment>
            <span {...titleStyle}></span><br />
            <span {...descriptionStyle} style={{ color: COLORS.GREY_LIGHT }}>
              {'|'}
            </span>
          </React.Fragment>
        </th>

        <th {...thStyle}>
          <React.Fragment>
            <span {...titleStyle}>VETERAN DOCUMENTS</span><br />
            <span {...descriptionStyle} style={{ color: 'red' }}>
              <ReaderLink appealId={appeal.id} appeal={appeal} redirectUrl={redirectUrl} longMessage />
            </span>
          </React.Fragment>
        </th>

        <th {...thStyle}>
          <React.Fragment>
            <span {...titleStyle}></span><br />
            <span {...descriptionStyle} style={{ color: COLORS.GREY_LIGHT }}>
              {'|'}
            </span>
          </React.Fragment>
        </th>

        <th {...thStyle}>
          <React.Fragment>
            <span {...titleStyle}>TYPE</span><br />
            <span {...descriptionStyle} className={appeal.caseType === 'CAVC' ? redType : null}>{appeal.caseType}</span>
          </React.Fragment>
        </th>

        <th className={primaryTask && primaryTask.documentId ? null : displayNone} {...thStyle}>
          <React.Fragment>
            <span {...titleStyle}></span><br />
            <span {...descriptionStyle} style={{ color: COLORS.GREY_LIGHT }}>
              {'|'}
            </span>
          </React.Fragment>
        </th>

        {<th className={primaryTask && primaryTask.documentId ? null : displayNone} {...thStyle}>
          <React.Fragment>
            <span {...divStyle}>
              <span {...titleStyle}>DECISION DOCUMENT ID</span><br />
              <CopyTextButton text={primaryTask ? primaryTask.documentId : null} />
            </span>
          </React.Fragment>
        </th>}

      </span>

    </CaseTitleScaffolding>;
  }
}

CaseTitle.propTypes = {
  appeal: PropTypes.object.isRequired,
  redirectUrl: PropTypes.string.isRequired,
  appealId: PropTypes.string.isRequired,
  taskType: PropTypes.string,
  analyticsSource: PropTypes.string
};

CaseTitle.defaultProps = {
  taskType: 'Draft Decision',
  analyticsSource: 'queue_task'
};

const mapStateToProps = (state, ownProps) => ({
  veteranCaseListIsVisible: state.ui.veteranCaseListIsVisible,
  userIsVsoEmployee: state.ui.userIsVsoEmployee,
  primaryTask: actionableTasksForAppeal(state, { appealId: ownProps.appealId })[0],
  canEditAod: state.ui.canEditAod
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleVeteranCaseList
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseTitle);

const CaseTitleScaffolding = (props) => <div {...containingDivStyling}>
  <ul {...ulStyling}>
    {props.children.map((child, i) => child && <li key={i} {...listItemStyling}
      className={i === 8 ? newRow : null}>{child}</li>)}
  </ul>
</div>;
