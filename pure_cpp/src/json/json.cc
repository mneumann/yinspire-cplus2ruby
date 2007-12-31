#include "json.h"
#include <string.h>
#include <math.h>

/* TODO:
 *   output indentation
 *   escape string (\0 characters in string?)
 */

struct jsonArrayItem
{
  jsonValue* value;
  jsonArrayItem* next;

  jsonArrayItem(jsonValue* value, jsonArrayItem* next=NULL)
  {
    @value = value;
    @next = next;
    @value->ref_incr();
  }

  ~jsonArrayItem()
  {
    @value->ref_decr();
  }
};

struct jsonHashItem
{
  jsonString* key;
  jsonValue* value;
  jsonHashItem* next;

  jsonHashItem(jsonString* key, jsonValue* value, jsonHashItem* next=NULL)
  {
    @key = key;
    @value = value;
    @next = next;

    @key->ref_incr();
    @value->ref_incr();
  }

  ~jsonHashItem()
  {
    @key->ref_decr();
    @value->ref_decr();
  }
};

jsonValue::jsonValue() 
{
  @ref_count = 1;
}

jsonValue::~jsonValue()
{
}

const char* jsonValue::type()
{
  return "value";
}

bool jsonValue::is_type(const char* t)
{
  return (strcmp(t, type()) == 0);
}

void jsonValue::ref_incr()
{
  @ref_count++;
}

void jsonValue::ref_decr()
{
  if (--@ref_count <= 0) delete this;
}

jsonNull* jsonValue::asNull()
{
  return dynamic_cast<jsonNull*>(this);
}

jsonTrue* jsonValue::asTrue()
{
  return dynamic_cast<jsonTrue*>(this);
}

jsonFalse* jsonValue::asFalse()
{
  return dynamic_cast<jsonFalse*>(this);
}

jsonNumber* jsonValue::asNumber()
{
  return dynamic_cast<jsonNumber*>(this);
}

jsonString* jsonValue::asString()
{
  return dynamic_cast<jsonString*>(this);
}

jsonArray* jsonValue::asArray()
{
  return dynamic_cast<jsonArray*>(this);
}

jsonHash* jsonValue::asHash()
{
  return dynamic_cast<jsonHash*>(this);
}

void jsonNull::output(std::ostream& s)
{
  s << "null";
}
const char* jsonNull::type()
{
  return "null";
}

void jsonTrue::output(std::ostream& s)
{
  s << "true";
}

const char* jsonTrue::type()
{
  return "true";
}

void jsonFalse::output(std::ostream& s)
{
  s << "false";
}

const char* jsonFalse::type()
{
  return "false";
}

jsonNumber::jsonNumber(double value)
{
  @value = value;
}

void jsonNumber::output(std::ostream& s) { 
  if (isinf(value))
  {
    if (value < 0.0)
    {
      s << "-Infinity";
    }
    else
    {
      s << "Infinity";
    }
  }
  else
  {
    s << value; 
  }
}

const char* jsonNumber::type()
{
  return "number";
}

jsonString::jsonString(std::string& value)
{
  @value = value;
}

jsonString::jsonString(const char* value)
{
  @value = value;
}

jsonString::jsonString(const char* _value, int len) : value(_value, len)
{
}

void jsonString::output(std::ostream& s)
{
  s << '"' << value << '"';
}

const char* jsonString::type()
{
  return "string";
}

jsonArrayIterator::jsonArrayIterator(jsonArray *array)
{
  @array = array;
  @array->ref_incr();
  @pos = @array->head;
}

jsonArrayIterator::~jsonArrayIterator()
{
  @array->ref_decr();
}

void jsonArrayIterator::next()
{
  if (@pos != NULL)
  {
    @pos = @pos->next;
  }
}

jsonValue *jsonArrayIterator::current()
{
  if (@pos != NULL)
  {
    return @pos->value;
  }
  else
  {
    return NULL;
  }
}

jsonHashIterator::jsonHashIterator(jsonHash *hash)
{
  @hash = hash;
  @hash->ref_incr();
  @pos = @hash->head;
}

jsonHashIterator::~jsonHashIterator()
{
  @hash->ref_decr();
}

void jsonHashIterator::next()
{
  if (@pos != NULL)
  {
    @pos = @pos->next;
  }
}

jsonString *jsonHashIterator::current_key()
{
  if (@pos != NULL)
  {
    return @pos->key;
  }
  else
  {
    return NULL;
  }
}

jsonValue *jsonHashIterator::current_value()
{
  if (@pos != NULL)
  {
    return @pos->value;
  }
  else
  {
    return NULL;
  }
}

jsonArray::jsonArray()
{
  head = tail = NULL;
}

jsonArray::~jsonArray()
{
  jsonArrayItem* j;
  for (jsonArrayItem* i=head; i != NULL; )
  {
    j = i->next;
    delete i;
    i = j;
  }
}

void jsonArray::output(std::ostream& s) 
{
  s << "[";
  for (jsonArrayItem* i=head; i != NULL; i=i->next)
  {
    if (i != head) s << ", ";
    i->value->output(s);
  }
  s << "]";
}

void jsonArray::push(jsonValue* value)
{
  jsonArrayItem* i = new jsonArrayItem(value);

  if (head == NULL)
  {
    head = tail = i; 
  }
  else
  {
    tail->next = i; 
    tail = i;
  }
}

/*void jsonArray::each(void (*iter)(jsonValue*, void*), void* data)
{
  for (jsonArrayItem* i=head; i != NULL; i=i->next)
  {
    iter(i->value, data);
  }
}
*/

jsonValue* jsonArray::get(int index)
{
  for (jsonArrayItem* i=head; i != NULL; i=i->next, index--)
  {
    if (index == 0)
      return i->value; 
  }
  return NULL;
}

const char* jsonArray::type()
{
  return "array";
}

jsonHash::jsonHash()
{
  head = tail = NULL;
}

jsonHash::~jsonHash()
{
  jsonHashItem* j;
  for (jsonHashItem* i=head; i != NULL; )
  {
    j = i->next;
    delete i;
    i = j;
  }
}

void jsonHash::output(std::ostream& s) 
{
  s << "{";
  for (jsonHashItem* i=head; i != NULL; i=i->next)
  {
    if (i != head) s << ", " << std::endl;
    i->key->output(s);
    s << ": ";
    i->value->output(s);
  }
  s << "}";
}

/*void jsonHash::each(void (*iter)(jsonString*, jsonValue*, void*), void* data)
{
  for (jsonHashItem* i=head; i != NULL; i=i->next)
  {
    iter(i->key, i->value, data);
  }
}
*/

jsonValue* jsonHash::get(const char* key)
{
  for (jsonHashItem* i=head; i != NULL; i=i->next)
  {
    if (i->key->value == key)
    {
      return i->value;
    }
  }
  return NULL;
}

jsonValue* jsonHash::get(std::string& key)
{
  return get(key.c_str());
}

jsonValue* jsonHash::get(jsonString* key)
{
  return get(key->value);
}

bool jsonHash::has_key(const char* key)
{
  return (get(key) != NULL);
}

bool jsonHash::has_key(std::string& key)
{
  return (get(key.c_str()) != NULL);
}

bool jsonHash::has_key(jsonString* key)
{
  return (get(key) != NULL);
}

bool jsonHash::get_bool(const char* key, bool default_value)
{
  jsonValue* v = get(key);
  if (v != NULL)
  {
    if (v->is_type("true"))
    {
      return true;
    }
    else if (v->is_type("false"))
    {
      return false;
    }
    else
    {
      throw "invalid type cast";
    }
  }
  else
  {
    return default_value;
  }
}

double jsonHash::get_number(const char* key, double default_value)
{
  jsonValue* v = get(key);
  if (v != NULL)
  {
    if (v->is_type("number"))
    {
      return ((jsonNumber*)v)->value;
    }
    else
    {
      throw "invalid type cast";
    }
  }
  else
  {
    return default_value;
  }
}

std::string& jsonHash::get_string(const char* key)
{
  jsonValue* v = get(key);
  if (v != NULL)
  {
    if (v->is_type("string"))
    {
      return ((jsonString*)v)->value;
    }
    else
    {
      throw "invalid type cast";
    }
  }
  else
  {
    throw "key not found";
  }
}

void jsonHash::set(const char* key, jsonValue* value)
{
  set(new jsonString(key), value);
}

void jsonHash::set(const char* key, double value)
{
  set(new jsonString(key), new jsonNumber(value));
}

void jsonHash::set(const char* key, int value)
{
  set(new jsonString(key), new jsonNumber(value));
}

void jsonHash::set(const char* key, bool value)
{
  set(new jsonString(key), value ? (jsonValue*)new jsonTrue() : (jsonValue*)new jsonFalse());
}

void jsonHash::set(const char* key, const char* value)
{
  set(new jsonString(key), new jsonString(value));
}

void jsonHash::set(const char* key, std::string& value)
{
  set(new jsonString(key), new jsonString(value));
}

void jsonHash::set(jsonString* key, jsonValue* value)
{
  if (head == NULL)
  {
    head = tail = new jsonHashItem(key, value); 
  }
  else
  {
    bool duplicate = false;

    for (jsonHashItem* i=head; i != NULL; i=i->next)
    {
      if (i->key->value == key->value)
      {
        i->key->ref_decr();
        i->value->ref_decr();
        i->key = key;
        i->value = value;
        duplicate = true;
        break;
      }
    }

    if (!duplicate)
    {
      jsonHashItem* t = new jsonHashItem(key, value);
      tail->next = t; 
      tail = t;
    }
  }
}

const char* jsonHash::type()
{
  return "hash";
}
