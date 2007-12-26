#ifndef __YINSPIRE__HASH__
#define __YINSPIRE__HASH__

#include <map>

template <class K, class V>
class Hash
{
  private:

    typedef typename std::map<K,V> T;
    typedef typename std::map<K,V>::const_iterator CI;
    typedef typename std::pair<K,V> P;
    T hash;

  public:

    inline bool
      has_key(const K& key)
      {
        return (@hash.count(key) > 0);
      }

    inline V&
      operator[](const K& key)
      {
        return @hash[key];
      }

    template<typename param> void
      each(void (*iter)(K&, V&, param), param data)
      {
        for (CI i = @hash.begin(); i != @hash.end(); i++) 
        {
          P p = *i;
          iter(p.first, p.second, data);
        }
      }

};

#endif
