import React from 'react';
import moment from 'moment';
import {
  PACKAGE_ACTION_MERGE_DESCRIPTION,
  PACKAGE_ACTION_MERGE_TITLE,
  PACKAGE_ACTION_MERGE_TEXTAREA_LABEL,
  PACKAGE_ACTION_MERGE_RADIO_LABEL,
  PACKAGE_ACTION_MODAL_DESCRIPTION,
  PACKAGE_ACTION_REMOVAL_TITLE,
  PACKAGE_ACTION_REMOVAL_TEXTAREA_LABEL,
  PACKAGE_ACTION_REASSIGN_DESCRIPTION,
  PACKAGE_ACTION_REASSIGN_TITLE,
  PACKAGE_ACTION_REASSIGN_TEXTAREA_LABEL,
  PACKAGE_ACTION_SPLIT_TITLE,
  PACKAGE_ACTION_SPLIT_TEXTAREA_LABEL
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

  if (dropdownType === 'removePackage' || dropdownType === 'reassignPackage' || dropdownType === 'splitPackage') {
    baseColumns.push(
      {
        cellClass: 'veteran-details-column',
        header: (
          <span id="veteran-details-label">
            Veteran Details
          </span>
        ),
        valueFunction: (row) => {
          const firstName = row.veteranInformation.veteran_name.first_name;
          const lastName = row.veteranInformation.veteran_name.last_name;
          const fileNumber = row.veteranInformation.file_number;

          return (
            <span className="veteran-info-value">
              <p>
                {`${firstName} ${lastName}\n(${fileNumber})`}
              </p>
            </span>
          );
        }
      }
    );
  }

  if (dropdownType === 'mergePackage') {
    baseColumns.push(
      {
        cellClass: 'vador-details-column',
        header: (
          <span id="vador-details-label">
            VA DOR
          </span>
        ),
        valueFunction: (row) => {
          const vaDate = moment.utc(row.correspondence.va_date_of_receipt).format('MM/DD/YYYY');

          return (
            <span className="veteran-info-value">
              <p>
                {`${vaDate}`}
              </p>
            </span>
          )
        }
      }
    );
  }

  return baseColumns;
};

export const getModalInformation = (dropdownType) => {
  switch (dropdownType) {
  case 'mergePackage':
    return {
      title: PACKAGE_ACTION_MERGE_TITLE,
      description: PACKAGE_ACTION_MERGE_DESCRIPTION,
      label: PACKAGE_ACTION_MERGE_TEXTAREA_LABEL,
      radioLabel: PACKAGE_ACTION_MERGE_RADIO_LABEL,
      placeholder: 'This is a reason for merge',
    };
  case 'removePackage':
    return {
      title: PACKAGE_ACTION_REMOVAL_TITLE,
      description: PACKAGE_ACTION_MODAL_DESCRIPTION,
      label: PACKAGE_ACTION_REMOVAL_TEXTAREA_LABEL
    };
  case 'reassignPackage':
    return {
      title: PACKAGE_ACTION_REASSIGN_TITLE,
      description: PACKAGE_ACTION_REASSIGN_DESCRIPTION,
      label: PACKAGE_ACTION_REASSIGN_TEXTAREA_LABEL
    };
  case 'splitPackage':
    return {
      title: PACKAGE_ACTION_SPLIT_TITLE,
      description: PACKAGE_ACTION_MODAL_DESCRIPTION,
      label: PACKAGE_ACTION_SPLIT_TEXTAREA_LABEL
    };
  default:
    return {
      title: '',
      description: '',
      label: ''
    };
  }
};
