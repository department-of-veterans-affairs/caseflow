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

//   describe('feature toggles', () => {
//     describe('poa_last_synced_at', () => {
//       it('hides PoaRefresh text when not toggled', () => {
//         const poaText = setup({ poaToggled: false });

//         expect(poaText).toMatchSnapshot();
//       });

//       it('shows PoaRefresh text when toggled', () => {
//         const poaText = setup({ poaToggled: true });

//         expect(poaText).toMatchSnapshot();
//       });
//     });
//   });
// });
import React from 'react';
import { PoaRefresh } from 'app/queue/components/PoaRefresh';
import { render, screen } from '@testing-library/react';

import { queueWrapper } from 'test/data/stores/queueStore';

describe('PoaRefresh', () => {
  const powerOfAttorney = { poa_last_synced_at: '04/08/2021' };

  // const Wrapper = ({ children }) => (
  //   <queueWrapper ui={{ featureToggles: { poa_last_synced_at: poaToggled } }}>
  //     {children}
  //   </queueWrapper>
  // );

   const setup = ({ poaToggled }) => {
    return render(
      <PoaRefresh powerOfAttorney={powerOfAttorney} />,
      { wrapper: queueWrapper, wrapperOptions: { ui: { featureToggles: { poa_last_synced_at: poaToggled } } } }
    );
  };

  describe('feature toggles', () => {
    describe('poa_last_synced_at', () => {
      it('hides PoaRefresh text when not toggled', () => {

        const { asFragment } = setup({ poaToggled: false });
        console.log(setup({ poaToggled: false }));
        console.log(asFragment());
        screen.debug();
        expect(asFragment()).toMatchSnapshot();
      });

      it('shows PoaRefresh text when toggled', () => {
        const { asFragment } = setup({ poaToggled: true });
        expect(asFragment()).toMatchSnapshot();
      });
    });
  });
});
