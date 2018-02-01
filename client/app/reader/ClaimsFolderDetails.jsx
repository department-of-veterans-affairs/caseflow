import React from 'react';
import _ from 'lodash';

import Accordion from '../components/Accordion';
import AccordionSection from '../components/AccordionSection';
import IssueList from './IssueList';

import { getClaimTypeDetailInfo } from '../reader/utils';
import { css } from 'glamor';

const rowDisplay = css({
  display: 'flex',
  justifyContent: 'space-between'
});

class ClaimsFolderDetails extends React.PureComponent {

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
          {!appealDoesntExist && <div>
            <div {...rowDisplay}>
              <div>
                <b>Veteran ID</b><br />
                <span>{appeal.vbms_id}</span>
              </div>
              <div>
                <b>Type</b><br />
                <span>{appeal.type}</span> {getClaimTypeDetailInfo(appeal)}
              </div>
              <div>
                <b>Docket Number</b><br />
                <span>{appeal.docket_number}</span>
              </div>
              <div>
                <b>Regional Office</b><br />
                <span>{`${appeal.regional_office.key} - ${appeal.regional_office.city}`}</span>
              </div>
            </div>
            <div {...rowDisplay}>
              <div>
                <b>Issues</b><br />
                <IssueList appeal={appeal} />
              </div>
            </div>
          </div>}
        </AccordionSection>
      </Accordion>
    </div>;
  }
}

export default ClaimsFolderDetails;
