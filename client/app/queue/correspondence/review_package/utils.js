import React from 'react';
import {
  PACKAGE_ACTION_MODAL_DESCRIPTION,
  PACKAGE_ACTION_REMOVAL_TITLE,
  PACKAGE_ACTION_REMOVAL_TEXTAREA_LABEL
} from '../../../../COPY';

export const getPackageActionColumns = (dropdownType) => {
  const baseColumns = [
    {
      cellClass: 'cm-packet-number-column',
      header: (
        <span id="cm-packet-number-label">
          CM Packet Number
        </span>
      ),
      valueFunction: (row) => (
        <span className="cm-packet-number-value">
          <p>{row.correspondence.cmp_packet_number}</p>
        </span>
      )
    },
    {
      cellClass: 'package-document-type-column',
      header: (
        <span id="package-document-type-label">
          Package Document Type
        </span>
      ),
      valueFunction: (row) => (
        <span className="package-document-value">
          <p>{row.packageDocumentType}</p>
        </span>
      )
    },
  ];

  if (dropdownType === 'removePackage') {
    baseColumns.push(
      {
        cellClass: 'veteran-details-column',
        header: (
          <span id="veteran-details-label">
            Veteran Details
          </span>
        ),
        valueFunction: (row) => (
          <span className="veteran-info-value">
            <p>
              {`${row.veteranInformation.veteran_name.first_name} ${row.veteranInformation.veteran_name.last_name}
              (${row.veteranInformation.file_number})`}
            </p>
          </span>
        )
      }
    );
  }
  // add the other column here for VADOR

  return baseColumns;
};

export const getModalInformation = (dropdownType) => {
  switch (dropdownType) {
  case 'removePackage':
    return {
      title: PACKAGE_ACTION_REMOVAL_TITLE,
      description: PACKAGE_ACTION_MODAL_DESCRIPTION,
      label: PACKAGE_ACTION_REMOVAL_TEXTAREA_LABEL
    };
  default:
    return '';
  }
};
