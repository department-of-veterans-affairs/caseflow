import React from 'react';
import { shallow } from 'enzyme';

import { ReadOnly } from 'app/hearings/components/details/ReadOnly';

describe('ReadOnly', () => {
  test('Matches snapshot with default props', () => {
    // Setup the test
    const example = 'Something\n\tElse';
    const label = 'example';

    // Run the test
    const readOnly = shallow(
      <ReadOnly label={label} text={example} />
    );

    // Assertions
    expect(readOnly.childAt(0).text()).toEqual(label);
    expect(readOnly.childAt(0).find('strong')).toHaveLength(1);
    expect(readOnly.childAt(1).text()).toEqual(example);
    expect(readOnly).toMatchSnapshot();
  });
})
;
