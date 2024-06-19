import React from 'react';
import { PoaRefresh } from 'app/queue/components/PoaRefresh';
import { mount } from 'enzyme';
import { render as rtlRender, screen } from '@testing-library/react';

import { queueWrapper } from 'test/data/stores/queueStore';


function customRender(ui, { wrapper: Wrapper, wrapperProps, ...options }) {
  if (Wrapper) {
    ui = <Wrapper {...wrapperProps}>{ui}</Wrapper>;
  }
  return rtlRender(ui, options);
}

const Wrapper = ({ children, ...props }) => {
  console.log('props', props);
  return queueWrapper({ children, ...props });
};

describe('PoaRefresh', () => {
  const powerOfAttorney = { poa_last_synced_at: '04/08/2021' };

  const setup = ({ poaToggled }) => {
    return customRender(
      <PoaRefresh powerOfAttorney={powerOfAttorney} />,
      {
        wrapper: Wrapper,
        wrapperProps: {
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
        const {asFragment} = setup({ poaToggled: false });

        screen.debug();

        // expect(poaText).toMatchSnapshot();
      });

      it.only('shows PoaRefresh text when toggled', () => {
        const {asFragment} = setup({ poaToggled: true });
        screen.debug();
        // expect(poaText).toMatchSnapshot();
      });
    });
  });
});
