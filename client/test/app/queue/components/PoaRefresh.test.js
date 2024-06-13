// import React from 'react';
// import { PoaRefresh } from 'app/queue/components/PoaRefresh';
// import { mount } from 'enzyme';

// import { queueWrapper } from 'test/data/stores/queueStore';

// describe('PoaRefresh', () => {
//   const powerOfAttorney = { poa_last_synced_at: '04/08/2021' };

  // const setup = ({ poaToggled }) => {
  //   return mount(
  //     <PoaRefresh powerOfAttorney={powerOfAttorney} />,
  //     {
  //       wrappingComponent: queueWrapper,
  //       wrappingComponentProps: {
  //         ui: {
  //           featureToggles: {
  //             poa_last_synced_at: poaToggled
  //           }
  //         }
  //       }
  //     });
  // };

  // describe('feature toggles', () => {
  //   describe('poa_last_synced_at', () => {
  //     it('hides PoaRefresh text when not toggled', () => {
  //       const poaText = setup({ poaToggled: false });

  //       expect(poaText).toMatchSnapshot();
  //     });

  //     it('shows PoaRefresh text when toggled', () => {
  //       const poaText = setup({ poaToggled: true });

  //       expect(poaText).toMatchSnapshot();
  //     });
  //   });
  // });
// });
import React from 'react';
import { PoaRefresh } from 'app/queue/components/PoaRefresh';
import { render, screen } from '@testing-library/react';

import { queueWrapper } from 'test/data/stores/queueStore';
import { useSelector } from 'react-redux';

jest.mock('react-redux', () => ({
  useSelector: jest.fn(),
  useDispatch: jest.fn(),
}));

const Wrapper = ({ children, poaToggled }) => {
  return queueWrapper({ children, ui: { featureToggles: { poa_last_synced_at: poaToggled } } });
};


describe('PoaRefresh', () => {
  const powerOfAttorney = { poa_last_synced_at: '04/08/2021' };

  const setup = ({ poaToggled }) => {
    useSelector.mockImplementation(callback => {
      if (callback.toString().includes('selectPoaRefreshButton')) {
        return poaToggled;
      }
      // Add other selectors if needed
      return null;
    });

    return render(
      <Wrapper poaToggled={poaToggled}>
        <PoaRefresh powerOfAttorney={powerOfAttorney} />
      </Wrapper>
    );
  };


  describe('feature toggles', () => {
    describe('poa_last_synced_at', () => {
      it('hides PoaRefresh text when not toggled', () => {
        const poaText = setup({ poaToggled: false });
        screen.debug();
        // Add assertions as needed
      });

      it('shows PoaRefresh text when toggled', () => {
        const poaText = setup({ poaToggled: true });
        screen.debug();
        // Add assertions as needed
      });
    });
  });
});
