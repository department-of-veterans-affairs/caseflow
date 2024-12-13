import { useEffect, useState } from 'react';

const usePageVisibility = (ref, threshold = 0, rootMargin = '0px 0px 0px 0px') => {
  const [isIntersecting, setIntersecting] = useState(false);

  useEffect(() => {
    if (ref.current) {
      const observer = new IntersectionObserver(([entry]) =>
        setIntersecting(entry.isIntersecting), { threshold, rootMargin }
      );

      observer.observe(ref.current);

      return () => {
        observer.disconnect();
      };
    }
  }, [ref]);

  return isIntersecting;
};

export default usePageVisibility;
