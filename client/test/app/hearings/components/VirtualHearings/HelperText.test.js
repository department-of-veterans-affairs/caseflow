import React from 'react';
import { shallow } from 'enzyme';

import { HelperText } from 'app/hearings/components/VirtualHearings/HelperText';

const label = 'Something helpful';

describe('HelperText', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const helperText = shallow(
      <HelperText label={label} />
    );

    // Assertions
    expect(helperText.text()).toEqual(label);
    expect(helperText).toMatchSnapshot();

  });
})
;
