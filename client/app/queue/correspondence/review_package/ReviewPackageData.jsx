/* eslint-disable camelcase */

import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import COPY from 'app/../COPY';
import { TitleDetailsSubheader } from 'app/components/TitleDetailsSubheader';
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

export const TitleDetailsSubheaderSection = ({ title, children }) => (
  <div {...listItemStyling}>
    <p>{title}</p>
    <div>
      {children}
    </div>
  </div>
);

class ReviewPackageData extends React.PureComponent {
  render = () => {
    return (
      <div>
        <CmpInfoScaffolding
          correspondence={this.props.correspondence}
          packageDocumentType = {this.props.packageDocumentType} />
      </div>
    );
  };
}

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

TitleDetailsSubheaderSection.propTypes = {
  children: PropTypes.node,
  title: PropTypes.string.isRequired
};

ReviewPackageData.propTypes = {
  correspondence: PropTypes.object,
  packageDocumentType: PropTypes.object
};

export default ReviewPackageData;
