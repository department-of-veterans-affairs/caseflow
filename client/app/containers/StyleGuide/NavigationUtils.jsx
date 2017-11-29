import React from 'react';
import classnames from 'classnames';

export const showSelectedClass = (index, selectedIndex) => {
  return classnames({ selected: index === selectedIndex });
}
