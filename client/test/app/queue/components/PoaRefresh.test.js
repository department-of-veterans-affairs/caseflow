import React from 'react';
import { PoaRefresh } from 'app/queue/components/PoaRefresh';
import { mount } from 'enzyme';

import { queueWrapper } from 'test/data/stores/queueStore';

describe('PoaRefresh', () => {
  const powerOfAttorney = { poa_last_synced_at: '04/08/2021' };

  const setup = ({ poaToggled }) => {
    return mount(
      <PoaRefresh powerOfAttorney={powerOfAttorney} />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
          ui: {
            featureToggles: {
              poa_last_synced_at: poaToggled
            }
          }
        }
      });
  };

  describe('feature toggles', () => {
    describe('poa_last_synced_at', () => {
      it('hides PoaRefresh text when not toggled', () => {
        const poaText = setup({ poaToggled: false });

        expect(poaText).toMatchSnapshot();
      });

      it('shows PoaRefresh text when toggled', () => {
        const poaText = setup({ poaToggled: true });

        expect(poaText).toMatchSnapshot();
      });
    });
  });
});
