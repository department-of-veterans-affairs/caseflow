import React, { Component } from 'react';
import { connect } from 'react-redux';
import { formatDate, formatArrayOfDateStrings } from '../../util/DateUtil';
import Accordion from '../../components/Accordion';
import AccordionSection from '../../components/AccordionSection';
import Table from '../../components/Table';
import { css } from 'glamor';

const columns = [
  { align: 'left',
    valueName: 'name' },
  {
    align: 'right',
    valueName: 'value' }
];

const styling = css({
  marginBottom: '30px',
  marginTop: '0px'
});

class HearingWorksheetDocs extends Component {

  render() {

    let { worksheet, worksheetAppeals } = this.props;

    const accordionTitle = 'Procedural History';

    return <div className="cf-app-segment">
      <Accordion
        style="bordered"
        defaultActiveKey={[accordionTitle]}
      >
        <AccordionSection
          id="procedural-history-details-accordion"
          className="usa-grid"
          disabled={false}
          title={accordionTitle}
        >
          <div>
            <div {...styling}>{worksheet.cached_number_of_documents} Documents in Claims Folder</div>

            {Object.values(worksheetAppeals).map((appeal, key) => {

              let notCertified = !appeal.certification_date;

              return <div key={appeal.id} id={appeal.id}>
                <div className="cf-hearings-column cf-top-margin">
                  Appeal Stream <span>{key + 1}</span> - Docket #<span>{appeal.docket_number}</span>
                  {appeal.contested_claim && <span className="cf-red-text">&nbsp;&nbsp;CC</span>}
                  {appeal.dic && <span className="cf-red-text">&nbsp;&nbsp;DIC</span>}
                </div>
                <div className="cf-push-left cf-hearings-column">
                  <Table
                    styling={styling}
                    columns={columns}
                    rowObjects={[
                      { name: <b>Prior BVA Decision</b>,
                        value: formatDate(appeal.prior_bva_decision_date) },
                      { name: <b>NOD</b>,
                        value: formatDate(appeal.nod_date) },
                      { name: <b>SOC</b>,
                        value: formatDate(appeal.soc_date) },
                      { name: <b>Form 9</b>,
                        value: formatDate(appeal.form9_date) }
                    ]}
                  />
                </div>
                <div className="cf-push-right cf-hearings-column">
                  <Table
                    styling={styling}
                    columns={columns}
                    rowObjects={[
                      { name: <b>SSOC</b>,
                        value: formatArrayOfDateStrings(appeal.ssoc_dates) },
                      { name: <b>Certification</b>,
                        value: notCertified ? <span>Not certified</span> : formatDate(appeal.certification_date) },
                      { name: <b>Docs since Certification</b>,
                        value: appeal.cached_number_of_documents_after_certification }
                    ]}
                  />
                </div>
              </div>;
            })}
          </div>
        </AccordionSection>
      </Accordion>
    </div>;
  }
}

// TODO map state to corresponding stream
export default connect()(HearingWorksheetDocs);
