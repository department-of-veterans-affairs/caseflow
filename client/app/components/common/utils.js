/* eslint no-undefined: 0 */

export const consolidatedEmptyValuesFor = (val) => {
  return [undefined, null, 'undefined', 'null'].includes(val) ? 'null' : val;
};
