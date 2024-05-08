import React from 'react';
import COPY from '../../../COPY';
import Link from '../../components/Link';
import { ExternalLinkIcon } from '../../components/icons/ExternalLinkIcon';
import { COLORS, ICON_SIZES } from '../../constants/AppConstants';

const styles = {
  linkStyles: {
    display: 'inline-flex',
    fontSize: 'small',
    cursor: 'pointer',
  },
  linkIconStyles: {
    marginLeft: '0.2em'
  }
};

export const tabConfig = [
  {
    label: COPY.CASE_LIST_TABLE_UNASSIGNED_LABEL,
    page: () => {
      return (
        <>
          <div style={{ display: 'flex', justifyContent: 'space-between' }} >
            Transcription owned by the Transcription Team are unassigned to a contractor:
            <Link>
              <span style={styles.linkStyles}>
                Transcription settings
                <ExternalLinkIcon style={styles.linkIconStyles} color={COLORS.PRIMARY} size={ICON_SIZES.SMALL} />
              </span>
            </Link>
          </div>
        </>
      );
    }
  },
  {
    label: COPY.TRANSCRIPTION_DISPATCH_ASSIGNED_TAB,
    page: () => {
      return (
        <>
          <p>Transcription owned by the Transcription Team are returned from contractor:</p>
        </>
      );
    }
  },
  {
    label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
    page: () => {
      return (
        <>
          <p>Transcription owned by the Transcription Team are returned from contractor:</p>
        </>
      );
    }
  },
  {
    label: COPY.TRANSCRIPTION_DISPATCH_ALL_TAB,
    page: () => {
      return (
        <>
          <p>All transcription owned by the Transcription team:</p>
        </>
      );
    }
  }
];

