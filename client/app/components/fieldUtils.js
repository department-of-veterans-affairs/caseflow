export const extractFieldProps = (props) => {
  const { id, className, label, inputRef } = props;
  return { id, className, label, inputRef };
};
