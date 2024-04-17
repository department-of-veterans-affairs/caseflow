/* eslint-disable camelcase */

import PropTypes from 'prop-types';
import React from 'react';
import COPY from 'app/../COPY';
import { TitleDetailsSubheader } from 'app/components/TitleDetailsSubheader';
import EditModal from '../modals/editModal';
import { useSelector } from 'react-redux';
import moment from 'moment';

export const TitleDetailsSubheaderSection = ({ title, children }) => (
  <div className="correspondence-rp-list-item-styling">
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
          packageDocumentType = {this.props.packageDocumentType}
          isReadOnly={this.props.isReadOnly} />
      </div>
    );
  };
}

const CmpInfoScaffolding = ({ isReadOnly }) => {
  const correspondence = useSelector(
    (state) => state.reviewPackage.correspondence
  );
  const packageDocumentType = useSelector(
    (state) => state.reviewPackage.packageDocumentType
  );

  const formattedVaDateOfReceipt = moment.utc(correspondence?.va_date_of_receipt).format('MM/DD/YYYY');
  const formattedPortalEntryDate = moment.utc(correspondence?.portal_entry_date).format('MM/DD/YYYY');

  return (
    <div>
      <div className="correspondence-rp-outer-div-style">
        <h2 className="correspondence-rp-h2-right-style"> {COPY.CORRESPONDENCE_REVIEW_CMP_INFO_TITLE}</h2>
        <EditModal isReadOnly={isReadOnly} />
      </div>

      <TitleDetailsSubheader id="caseTitleDetailsSubheader">
        <TitleDetailsSubheaderSection title="VA DOR">
          {formattedVaDateOfReceipt}
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
        <TitleDetailsSubheaderSection title="Portal Entry Date">
          {formattedPortalEntryDate}
        </TitleDetailsSubheaderSection>
      </TitleDetailsSubheader>
    </div>
  );
};

CmpInfoScaffolding.propTypes = {
  packageDocumentType: PropTypes.object,
  correspondence: PropTypes.object,
  isReadOnly: PropTypes.bool
};

TitleDetailsSubheaderSection.propTypes = {
  children: PropTypes.node,
  title: PropTypes.string.isRequired
};

ReviewPackageData.propTypes = {
  correspondence: PropTypes.object,
  packageDocumentType: PropTypes.object,
  isReadOnly: PropTypes.bool
};

export default ReviewPackageData;
