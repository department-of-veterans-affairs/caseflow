/* eslint-disable camelcase */

import { css } from 'glamor';
import PropTypes from 'prop-types';
import React, { useState } from 'react';
import COPY from 'app/../COPY';
import ApiUtil from 'app/util/ApiUtil';
import { TitleDetailsSubheader } from 'app/components/TitleDetailsSubheader';
import Button from 'app/components/Button';
import EditModal from '../modals/editModal';

const listItemStyling = css({
  display: 'inline-block',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':not(:last-child)': {
    '& > div': {
    },
    '& > *': {
      paddingRight: '1.5rem'
    }
  },
  '& > p': {
    fontWeight: 'bold',
    fontSize: '17px',
    marginBottom: '12px',
    marginTop: '0',
    color: '#323a45',
    lineHeight: '1.3'
  },
  '& > div': { minHeight: '22px' }
});

const cmpDocumentStyling = css({
  marginTop: '5%'
});

const correspondenceStyling = css({
  border: '1px solid #dee2e6'
});

const paginationStyle = css({
  marginTop: '2%',
  marginLeft: '1.5%'
});

export const TitleDetailsSubheaderSection = ({ title, children }) => (
  <div {...listItemStyling}>
    <p>{title}</p>
    <div>
      {children}
    </div>
  </div>
);

class ReviewPackageData extends React.PureComponent {
  constructor (props) {
    super(props);
    this.state = {
      correspondence: null,
      package_document_type: null,
      correspondence_documents: null,
      totalDocuments: 0,
      currentDocument: 0
    };
  }

  componentDidMount () {
    const correspondence = this.props;

    ApiUtil.get(`/queue/correspondence/${correspondence.correspondenceId}`).then((response) => {
      this.setState({
        correspondence: response.body.correspondence,
        package_document_type: response.body.package_document_type,
        correspondence_documents: response.body.correspondence_documents,
        totalDocuments: response.body.correspondence_documents.length,
      });
    });
  }

  render = () => {
    return (
      <div>
        <CmpInfoScaffolding
          correspondence={this.state?.correspondence}
          packageDocumentType = {this.state?.package_document_type} />
        <CmpDocuments
          correspondence_documents = {this.state?.correspondence_documents}
          totalCount = {this.state?.totalDocuments} />
      </div>
    );
  };
}

const CmpDocuments = (props) => {
  const { correspondence_documents, totalCount } = props;

  const [selectedId, setSelectedId] = useState(0);

  const paginationText = `Viewing 1-${totalCount} out of ${totalCount} total documents`;

  const setCurrentDocument = (index) => {
    setSelectedId(index);
  };

  return (
    <div {...cmpDocumentStyling} >
      <h2> {COPY.DOCUMENT_PREVIEW} </h2>
      <div {...correspondenceStyling}>
        <div {...paginationStyle}> {paginationText} </div>
        <table className="correspondence-document-table">
          <tr>
            <th > Document Type </th>
            <th className="cf-txt-c"> Action </th>
          </tr>
          { correspondence_documents?.map((document, index) => {
            return (
              <tr>
                <td style={{ background: selectedId === index ? '#0071bc' : 'white',
                  color: selectedId === index ? 'white' : '#0071bc' }}
                onClick={() => setCurrentDocument(index)}> {document?.document_title}
                </td>
                <td className="cf-txt-c">
                  <Button linkStyling >
                    <span>Edit</span>
                  </Button>
                </td>
              </tr>
            );
          })}
        </table>
      </div>
    </div>
  );
};

const CmpInfoScaffolding = (props) => {
  const packageDocumentType = props.packageDocumentType;
  const correspondence = props.correspondence;
  const date = new Date(correspondence?.portal_entry_date);
  const dateOfReceipt = new Date(correspondence?.va_date_of_receipt);
  const customDate = date && `${(date.getMonth() + 1).toString().
    padStart(2, '0')}/${(date.getDate()).toString().
      padStart(2, '0')}/${date.getFullYear()}`;

  const dateOfReceiptCustomDate = dateOfReceipt && `${(dateOfReceipt.getMonth() + 1).toString().
    padStart(2, '0')}/${(dateOfReceipt.getDate()).toString().
      padStart(2, '0')}/${dateOfReceipt.getFullYear()}`;

  return (
    <div>
      <div style={{ display: 'inline-flex' }}>
        <h2 style={{ marginRight: '20px' }}> {COPY.CORRESPONDENCE_REVIEW_CMP_INFO_TITLE}</h2>
        <EditModal />
      </div>

      <TitleDetailsSubheader id="caseTitleDetailsSubheader">
        <TitleDetailsSubheaderSection title="Portal Entry Date">
          {customDate}
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="Source Type">
          {correspondence?.source_type}
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="Package Document Type">
          {packageDocumentType?.name}
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="CM Packet Number">
          {correspondence?.cmp_packet_number}
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="CMP Queue Name">
          BVA Intake
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="VA DOR">
          {dateOfReceiptCustomDate}
        </TitleDetailsSubheaderSection>
      </TitleDetailsSubheader>
    </div>
  );
};

CmpInfoScaffolding.propTypes = {
  packageDocumentType: PropTypes.object,
  correspondence: PropTypes.object
};

CmpDocuments.propTypes = {
  correspondence_documents: PropTypes.array,
  totalCount: PropTypes.number
};

TitleDetailsSubheaderSection.propTypes = {
  children: PropTypes.node,
  title: PropTypes.string.isRequired
};

ReviewPackageData.propTypes = {
  correspondenceId: PropTypes.string
};

export default ReviewPackageData;
