import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { CATEGORIES } from './constants';
import { COLORS } from '../constants/AppConstants';
import ReaderLink from './ReaderLink';
import CopyTextButton from '../components/CopyTextButton';
import { toggleVeteranCaseList } from './uiReducer/uiActions';
import COPY from '../../COPY.json';
import DocketTypeBadge from './components/DocketTypeBadge';

import { actionableTasksForAppeal } from './selectors';

const containingDivStyling = css({
  borderBottom: `1px solid ${COLORS.GREY_LIGHT}`,
  display: 'block',
  // Offsets the padding from .cf-app-segment--alt to make the bottom border full width.
  margin: '-2rem -4rem 0 -4rem',
  padding: '0 0 1.5rem 4rem',

  '& > *': {
    display: 'inline-block',
    margin: '0'
  }
});

const headerStyling = css({
  paddingRight: '2.5rem'
});

const newHeaderStyling = css({
  fontSize: '34px',
  fontWeight: 'bold'
});

const headerSupportStyling = css({
  fontSize: '18px',
  color: 'grey',
  marginLeft: '2px'
});

const listStyling = css({
  listStyleType: 'none',
  verticalAlign: 'super',
  padding: '1rem 0 0 0'
});

const listItemStyling = css({
  display: 'inline',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  ':not(:first-child)': { paddingLeft: '1.5rem' }
});

const viewCasesStyling = css({
  cursor: 'pointer',
  display: 'none'
});

const headingStyling = css({
  marginBottom: '0.5rem'
});

const newStyling = css({
  margin: '100px 200px 100px 0px'
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
  margin: '0  0 0'
});

const rightMargin = css({
  marginRight: '40px !important'
});

const titleStyle = css({
  fontWeight: 'bold',
  textAlign: 'center',
  fontSize: '12px',
  marginLeft: '5px'
});

const divStyle = css({
  marginRight: '10px'
});

const redType = css({
  color: 'red'
});

const displayNone = css({
  display: 'none'
});

const editButton = css({
  float: 'right'
});

const thStyle = css({
  border: 'none',
  backgroundColor: '#F8F8F8',
  margin: '0 0 0 20px'
});

const descriptionStyle = css({
  marginLeft: '5px'
});

const caseInfo = css({
  backgroundColor: '#F8F8F8',
  paddingBottom: '50px',
});

class CaseTitle extends React.PureComponent {
  render = () => {
    const {
      appeal,
      primaryTask,
      appealId,
      redirectUrl,
      taskType,
      analyticsSource,
      veteranCaseListIsVisible
    } = this.props;

    console.log('--CaseTitle--');
    console.log(appeal);
    console.log(this.props);
    console.log(this.props.children);
    console.log(primaryTask);
    console.log(appealId);
    console.log(redirectUrl);
    console.log(taskType);
    console.log(analyticsSource);
    console.log(veteranCaseListIsVisible);
    //console.log(actionableTasksForAppeal(null, { appealId: appealId })[0]);

    return <CaseTitleScaffolding /*heading={appeal.veteranFullName}*/{...caseInfo}>
      <React.Fragment>
        <span {...newHeaderStyling}>{appeal.veteranFullName}</span>
      </React.Fragment>

      <span>
        <span {...headerSupportStyling}>{' Veteran ID '}</span>
        <CopyTextButton text={appeal.veteranFileNumber} />
      </span>

      { /*!this.props.userIsVsoEmployee && <ReaderLink
        appealId={appealId}
        analyticsSource={CATEGORIES[analyticsSource.toUpperCase()]}
        redirectUrl={redirectUrl}
        appeal={appeal}
        taskType={taskType}
        longMessage /> */}

      {
        /*<span {...viewCasesStyling}>
          <Link onClick={this.props.toggleVeteranCaseList}>
            { veteranCaseListIsVisible ? 'Hide' : 'View' } all cases
          </Link>
        </span>*/
      }
      <br/>

      <span {...caseInfo}>
        <th {...thStyle}>
          <React.Fragment>
            <span {...titleStyle} className={rightMargin}>{COPY.CASE_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL.toUpperCase()}</span><br/>
            <span {...spanStyle} {...positionAbsolute}>
              <DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />{appeal.docketNumber}
            </span>
          </React.Fragment>
        </th>

        <th {...thStyle}>
          <React.Fragment>
            <span {...titleStyle}>{'VETERAN DOCUMENTS'}</span><br/>
            <span {...descriptionStyle}>
              <ReaderLink appealId={appeal.id} appeal={appeal} redirectUrl={window.location.pathname} longMessage />
            </span>
          </React.Fragment>
        </th>

        <th {...thStyle}>
          <React.Fragment>
              <span {...titleStyle}>{'TYPE'}</span><br/>
              <span  {...descriptionStyle} className={appeal.caseType == 'CAVC' ? redType : null}>{appeal.caseType}</span>
          </React.Fragment>
        </th>

        {<th className={primaryTask && primaryTask.documentId ? null : displayNone}  {...thStyle}>
          <React.Fragment>
            <span {...divStyle}>
             <span {...titleStyle}>{'DECISION DOCUMENT ID'}</span><br/>
             <CopyTextButton text={primaryTask ? primaryTask.documentId : null} />
            </span>
          </React.Fragment>
        </th>}

        <th {...thStyle}>
          <React.Fragment>
            <br/>
            <Link onClick={this.props.toggleVeteranCaseList}>
              { veteranCaseListIsVisible ? 'Hide' : 'View' } all cases
            </Link>
          </React.Fragment>
        </th>
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

const mapStateToProps = (state) => ({
  veteranCaseListIsVisible: state.ui.veteranCaseListIsVisible,
  userIsVsoEmployee: state.ui.userIsVsoEmployee,
  primaryTask: actionableTasksForAppeal(state, { appealId: Object.keys(state.queue.appealDetails)[0]})[0]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleVeteranCaseList
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseTitle);

const CaseTitleScaffolding = (props) => <div>
  <ul>
    {props.children.map((child, i) => child && <li key={i} {...listItemStyling}>{child}</li>)}
    {/*props.children.map((child, i) => child && <span {...caseInfo} className={i==0 ? rightMargin : null} key={i}>{child}</span>)*/}
  </ul>
</div>;

/*const CaseTitleScaffolding = (props) => <div {...containingDivStyling}>
  <ul {...listStyling}>
    {props.children.map((child, i) => child && <li key={i} {...listItemStyling}>{child}</li>)}
  </ul>
</div>;*/
