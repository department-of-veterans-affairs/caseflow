import React from 'react';
import _ from 'lodash';

import Accordion from '../components/Accordion';
import AccordionSection from '../components/AccordionSection';

class ClaimsFolderDetails extends React.PureComponent {

  getClaimTypeDetailInfo() {
    const { appeal } = this.props;
    let appealTypeInfo = '';

    if (appeal.cavc && appeal.aod) {
      appealTypeInfo = 'AOD, CAVC';
    } else if (appeal.cavc) {
      appealTypeInfo = 'CAVC';
    } else if (appeal.aod) {
      appealTypeInfo = 'AOD';
    }

    return <span className="claim-detail-type-info">{appealTypeInfo}</span>;
  }

  render() {
    const { appeal, documents } = this.props;
    const appealDoesntExist = _.isEmpty(appeal);
    const docsViewedCount = _.filter(documents, 'opened_by_current_user').length;

    return <div className="cf-claims-folder-details">
      <div>
        { !appealDoesntExist && <h1 className="cf-push-left">{appeal.veteran_full_name}'s Claims Folder</h1> }
        <p className="cf-push-right">
          You've viewed { docsViewedCount } out of { documents.length } documents
        </p>
      </div>
      <Accordion style="bordered" accordion={false} defaultActiveKey={['Claims Folder details']}>
        <AccordionSection id="claim-folder-details-accordion" className="usa-grid"
          disabled={appealDoesntExist} title={appealDoesntExist ? 'Loading...' : 'Claims folder details'}>
          {!appealDoesntExist &&
          <div>
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
                  {appeal.issues.map((issue) =>
                    <li key={`${issue.appeal_id}_${issue.vacols_sequence_id}`}><span>
                      {issue.type.label}: {issue.levels ? issue.levels.join(', ') : ''}
                    </span></li>
                  )}
                </ol>
            </div>
          </div>}
        </AccordionSection>
      </Accordion>
    </div>;
  }
}

export default ClaimsFolderDetails;
