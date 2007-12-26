#ifndef __YINSPIRE__JSON__
#define __YINSPIRE__JSON__

#include <ostream>
#include <string>

struct jsonArrayItem;
struct jsonHashItem;

class jsonValue {
  public:
    jsonValue();
    virtual ~jsonValue();
    virtual const char* type();
    bool is_type(const char* t);
    void ref_incr();
    void ref_decr();
    virtual void output(std::ostream& s) = 0;
  private:
    int ref_count;
};

class jsonNull : public jsonValue 
{
  public:
    virtual void output(std::ostream& s);
    virtual const char* type();
};


class jsonTrue : public jsonValue
{
  public:
    virtual void output(std::ostream& s);
    virtual const char* type();
};

class jsonFalse : public jsonValue
{
  public:
    virtual void output(std::ostream& s);
    virtual const char* type();
};

class jsonNumber : public jsonValue
{
  public:

    double value;

  public:

    jsonNumber(double value);
    virtual void output(std::ostream& s);
    virtual const char* type();
};

class jsonString : public jsonValue
{
  public:

    std::string value;

  public:

    jsonString(std::string& value);
    jsonString(const char* value);
    jsonString(const char* _value, int len);

    virtual void output(std::ostream& s);
    virtual const char* type();
};

class jsonArray : public jsonValue
{
  private:

    jsonArrayItem* head;
    jsonArrayItem* tail;

  public:

    jsonArray();
    virtual ~jsonArray();
    virtual void output(std::ostream& s);
    void push(jsonValue* value);
    void each(void (*iter)(jsonValue*, void*), void* data);
    jsonValue *get(int index);
    virtual const char* type();
};

class jsonHash : public jsonValue
{
  private:

    jsonHashItem* head;
    jsonHashItem* tail;

  public:

    jsonHash();
    virtual ~jsonHash();
    virtual void output(std::ostream& s);
    void each(void (*iter)(jsonString*, jsonValue*, void*), void* data);
    jsonValue* get(const char* key);
    jsonValue* get(std::string& key);
    jsonValue* get(jsonString* key);
    bool has_key(const char* key);
    bool has_key(std::string& key);
    bool has_key(jsonString* key);
    bool get_bool(const char* key, bool default_value);
    double get_number(const char* key, double default_value);
    std::string& get_string(const char* key);
    void set(const char* key, jsonValue* value);
    void set(const char* key, double value);
    void set(const char* key, int value);
    void set(const char* key, bool value);
    void set(const char* key, const char* value);
    void set(const char* key, std::string& value);
    void set(jsonString* key, jsonValue* value);
    virtual const char* type();
};

#endif
