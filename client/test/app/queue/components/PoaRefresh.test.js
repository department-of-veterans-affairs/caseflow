import React from 'react';
import { PoaRefresh } from 'app/queue/components/PoaRefresh';
import { render, screen } from '@testing-library/react';
import { queueWrapper } from 'test/data/stores/queueStore';
import COPY from 'COPY';
import { formatDateStr } from 'app/util/DateUtil';
import * as redux from 'react-redux';
import { selectPoaRefreshButton, selectIsVhaBusinessLine } from 'app/nonComp/selectors/nonCompSelectors.js';

function customRender(ui, { wrapper: Wrapper, wrapperProps, ...options }) {
  if (Wrapper) {
    ui = <Wrapper {...wrapperProps}>{ui}</Wrapper>;
  }
  return render(ui, options);
}

const Wrapper = ({ children, ...props }) => {
  return queueWrapper({ children, ...props });
};

describe('PoaRefresh', () => {
  const powerOfAttorney = { poa_last_synced_at: '2023-06-25T12:00:00Z' };
  const appealId = '1234';

  const setup = ({ poaToggled }) => {
    // Use jest.spyOn to mock useSelector
    jest.spyOn(redux, 'useSelector').mockImplementation(selector => {
      if (selector === selectPoaRefreshButton) {
        return poaToggled;
      }
      if (selector === selectIsVhaBusinessLine) {
        return false;
      }
      return undefined;
    });

    return customRender(
      <PoaRefresh
        powerOfAttorney={powerOfAttorney}
        appealId={appealId}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          initialState: {
            ui: {
              featureToggles: {
                poa_last_synced_at: poaToggled
              }
            },
            nonComp: {
              poaRefreshButton: poaToggled,
              isVhaBusinessLine: false
            }
          }
        }
      }
    );
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('feature toggles', () => {
    describe('poa_last_synced_at', () => {
      it('hides PoaRefresh text when not toggled', () => {
        const { asFragment } = setup({ poaToggled: false });

        expect(screen.queryByText(COPY.CASE_DETAILS_POA_REFRESH_BUTTON_EXPLANATION)).not.toBeInTheDocument();
        const expectedSyncDate = formatDateStr(powerOfAttorney.poa_last_synced_at);
        const expectedSyncText = COPY.CASE_DETAILS_POA_LAST_SYNC_DATE_COPY.replace('%(poaSyncDate)s', expectedSyncDate);
        expect(screen.queryByText(expectedSyncText)).not.toBeInTheDocument();
        expect(asFragment()).toMatchSnapshot(); // Correctly call toMatchSnapshot
      });

      it('shows PoaRefresh text when toggled', () => {
        const { asFragment } = setup({ poaToggled: true });

        expect(screen.getByText(COPY.CASE_DETAILS_POA_REFRESH_BUTTON_EXPLANATION)).toBeInTheDocument();
        const expectedSyncDate = formatDateStr(powerOfAttorney.poa_last_synced_at);
        const expectedSyncText = COPY.CASE_DETAILS_POA_LAST_SYNC_DATE_COPY.replace('%(poaSyncDate)s', expectedSyncDate);
        expect(screen.getByText(expectedSyncText)).toBeInTheDocument();
        expect(asFragment()).toMatchSnapshot(); // Correctly call toMatchSnapshot
      });
    });
  });
});
