import React from 'react';
import { render, screen } from '@testing-library/react';
import CaseDetailsView from "../../../app/queue/CaseDetailsView";
import { queueWrapper as Wrapper } from 'test/data/stores/queueStore';
import { amaAppeal, legacyAppeal, powerOfAttorney } from '../../data/appeals';
import COPY from '../../../COPY';

const defaultProps = {
  userCanScheduleVirtualHearings: true,
  userCanAccessReader: true,
  userCanEditUnrecognizedPOA: true,
  vsoVirtualOptIn: true,
};

const renderCaseDetailsView = (hasNotifications, appealData) => {
  const stagedAppealData = {
    [appealData.id]: {
      ...appealData,
      hasPOA: true,
      hasNotifications,
      isPaperCase: true,
      powerOfAttorney,
      appellantType: 'VeteranClaimant'
    }
  };

  const storeValues = {
    queue: {
      appeals: [stagedAppealData],
      appealDetails: stagedAppealData,
      mostRecentlyHeldHearingForAppeal: {},
      loadingAppealDetail: {
        [appealData.externalId]: {
          powerOfAttorney: {
            loading: true
          },
          veteranInfo: {
            loading: false
          }
        }
      },
      docCountForAppeal: {
        [appealData.externalId]: {
          docCountText: 0,
          loading: false
        }
      },
    },
    ui: {
      organizations: [
        {
          name: 'BVA Intake',
          url: 'bva-intake'
        }
      ],
      poaAlert: {
        powerOfAttorney
      }
    }
  };

  const props = { ...defaultProps, appealId: appealData.id };

  return render(
    <Wrapper {...storeValues} >
      <CaseDetailsView {...props} />
    </Wrapper>
  );
};

describe('NotificationsLink', () => {
  describe('When there are notifications', () => {
    it('link appears with ama appeal', () => {
      renderCaseDetailsView(true, amaAppeal);

      expect(screen.getByRole('link', { name: COPY.VIEW_NOTIFICATION_LINK })).toBeTruthy();
    });

    it('link appears with legacy appeal', () => {
      renderCaseDetailsView(true, legacyAppeal);

      expect(screen.getByRole('link', { name: COPY.VIEW_NOTIFICATION_LINK })).toBeTruthy();
    });
  });

  describe('When there are\'not notifications', () => {
    // ama without notifications
    it('link does not appears with ama appeal', () => {
      const {container} = renderCaseDetailsView(false, amaAppeal);
      const link = container.querySelector('#notification-link');

      expect(link).toBeNull()
    // legacy without notifications
    });

    it('link does not appears with legacy appeal', () => {
      const {container} = renderCaseDetailsView(false, legacyAppeal);
      const link = container.querySelector('#notification-link');

      expect(link).toBeNull();
    });
  });
});