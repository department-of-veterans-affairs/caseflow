import React from 'react';
import { connect } from 'react-redux';
import * as Constants from './constants';

import Accordion from '../components/Accordion';
import AccordionHeader from '../components/AccordionHeader';

const TYPE_INFO = {
  aod: { text: 'AOD',
    className: 'claim-detail-aod' },
  cavc: { text: 'CAVC',
    className: 'claim-detail-cavc' },
  both: { text: 'AOD, CAVC',
    className: 'claim-detail-aod' },
  none: { text: '',
    className: '' }
};

class ClaimsFolderDetails extends React.PureComponent {

  getClaimTypeDetailInfo() {
    const { appeal } = this.props;
    let obj = TYPE_INFO.none;

    if (appeal.cavc && appeal.aod) {
      obj = TYPE_INFO.both;
    } else if(appeal.cavc) {
      obj = TYPE_INFO.cavc;
    } else if (appeal.aod) {
      obj = TYPE_INFO.aod;
    }

    return <span className={obj.className}>{obj.text}</span>;
  }

  render() {
    const { appeal } = this.props;

    if (!appeal) {
      return <p className="loading-text">Loading...</p>;
    }

    return <div className="cf-claims-folder-details">
      <h1>{appeal.veteran_full_name}'s Claims Folder</h1>
      <Accordion style="bordered" accordion={false} defaultActiveKey={['Claims Folder details']}>
        <AccordionHeader className="usa-grid" title="Claims folder details" key={1}>
          <div className="usa-width-one-fourth">
            <b>Veteran ID</b><br />
            <span>{appeal.vbms_id}</span>
          </div>
          <div className="usa-width-one-fourth">
            <b>Type</b><br />
            <span>{appeal.type}</span> {this.getClaimTypeDetailInfo()}
          </div>
          <div className="usa-width-one-fourth">
            <b>Docket Number</b><br />
            <span>{appeal.docket_number}</span>
          </div>
          <div className="usa-width-one-fourth">
            <b>Regional Office</b><br />
            <span>{`${appeal.regional_office.key} - ${appeal.regional_office.city}`}</span>
          </div>
          <div className="usa-width-one-whole claims-folder-issues">
              <b>Issues</b><br />
              <ol>
                {appeal.issues.map((issue, index) =>
                  <li key={index}><span>
                    {issue.type.label}: {issue.levels ? issue.levels.join(', ') : ''}
                  </span></li>
                )}
              </ol>
          </div>
        </AccordionHeader>
      </Accordion>
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => ({
  handleToggleCommentOpened(docId) {
    dispatch({
      type: Constants.TOGGLE_COMMENT_LIST,
      payload: {
        docId
      }
    });
  }
});

export default connect(
  null,
  mapDispatchToProps
)(ClaimsFolderDetails);
