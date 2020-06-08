import { connect } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import React, { Component } from 'react';

import { Accordion } from '../../../components/Accordion';
import { formatDateStr, formatArrayOfDateStrings } from '../../../util/DateUtil';
import AccordionSection from '../../../components/AccordionSection';
import Table from '../../../components/Table';

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
            <div {...styling} className="worksheetDocs">
              {worksheet.cached_number_of_documents} Documents in Claims Folder
            </div>

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
                    getKeyForRow = {(index) => index}
                    rowObjects={[
                      { name: <b>Prior BVA Decision</b>,
                        value: formatDateStr(appeal.prior_bva_decision_date) },
                      { name: <b>NOD</b>,
                        value: formatDateStr(appeal.nod_date) },
                      { name: <b>SOC</b>,
                        value: formatDateStr(appeal.soc_date) },
                      { name: <b>Form 9</b>,
                        value: formatDateStr(appeal.form9_date) }
                    ]}
                  />
                </div>
                <div className="cf-push-right cf-hearings-column">
                  <Table
                    styling={styling}
                    columns={columns}
                    getKeyForRow = {(index) => index}
                    rowObjects={[
                      { name: <b>SSOC</b>,
                        value: formatArrayOfDateStrings(appeal.ssoc_dates) },
                      { name: <b>Certification</b>,
                        value: notCertified ? <span>Not certified</span> : formatDateStr(appeal.certification_date) },
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

HearingWorksheetDocs.propTypes = {
  worksheet: PropTypes.shape({
    cached_number_of_documents: PropTypes.number
  }),
  worksheetAppeals: PropTypes.object
};

export default connect()(HearingWorksheetDocs);
