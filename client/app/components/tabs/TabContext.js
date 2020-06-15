import React, { useMemo } from 'react';
import PropTypes from 'prop-types';

export const TabContext = React.createContext(null);

export const useUniquePrefix = () => {
  const [id, setId] = React.useState(null);

  React.useEffect(() => {
    setId(`cf-tabs-${Math.round(Math.random() * 1e5)}`);
  }, []);

  return id;
};

const propTypes = {
  children: PropTypes.arrayOf(PropTypes.element).isRequired,
  idPrefix: PropTypes.string,
  onSelect: PropTypes.func,
  value: PropTypes.string.isRequired,
};

export const TabContextProvider = ({
  children,
  idPrefix = useUniquePrefix(),
  value,
  onSelect,
}) => {
  const context = useMemo(() => ({ idPrefix, onSelect, value }), [
    idPrefix,
    onSelect,
    value,
  ]);

  return <TabContext.Provider value={context}>{children}</TabContext.Provider>;
};
TabContextProvider.propTypes = propTypes;

export default TabContextProvider;
