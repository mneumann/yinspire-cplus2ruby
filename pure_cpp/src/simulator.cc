#include <math.h>
#include <string>
#include "simulator.h"
#include "json/json_parser.h"

Simulator::Simulator()
{
  @schedule_current_time = 0.0;
  @schedule_step = INFINITY;
  @schedule_next_step = @schedule_current_time + @schedule_step;
  @schedule_stepping_list_root = NULL;
  @stimuli_tolerance = 0.0;
  @stat_event_counter = 0;
  @stat_fire_counter = 0;
}

void
Simulator::entity_register_type(const char *type, entity_factory_t factory)
{
  @types[type] = factory;
}

NeuralEntity*
Simulator::entity_allocate(const char* type)
{
  entity_factory_t factory = @types[type];
  return factory();
}

void
Simulator::load(const char *filename)
{
  jsonHash *data = jsonParser::parse_file_mmap(filename)->asHash();

  std::string format = data->get("format")->asString()->value;

  if (format != "yinspire.2")
  {
    throw "unrecognized data format";
  }

  jsonHash *templates = data->get("templates")->asHash();
  jsonArray *entities = data->get("entities")->asArray();
  jsonArray *connections = data->get("connections")->asArray();
  jsonHash *events = data->get("events")->asHash();

  /*
   * construct entities
   */
  jsonArrayIterator_EACH(entities, e)
  {
    jsonArray *entity_spec = e->asArray();
    jsonString *id = entity_spec->get(0)->asString();
    jsonString *template_name = entity_spec->get(1)->asString();

    jsonArray *t = templates->get(template_name)->asArray();

    jsonString *type = t->get(0)->asString();
    jsonHash *hash = t->get(1)->asHash();

    NeuralEntity *entity = entity_allocate(type->value.c_str());

    entity->set_id(strdup(id->asString()->value.c_str()));
    entity->set_simulator(this);
    @entities[entity->get_id()] = entity;

    entity->load(hash);
  }

  /*
   * connect entities
   */
  jsonArrayIterator_EACH(connections, conn)
  {
    NeuralEntity *from = NULL;
    jsonArrayIterator_EACH(conn->asArray(), i)
    {
      std::string &id = i->asString()->value;
      NeuralEntity *e = @entities[id.c_str()]; 
      if (from == NULL) from = e;
      else from->connect(e);
    } 
  }

  /*
   * events
   */
  jsonHashIterator_EACH(events, key, val) 
  {
    NeuralEntity *entity = @entities[key->value.c_str()];
    jsonArrayIterator_EACH(val->asArray(), e)
    {
      entity->stimulate(e->asNumber()->value, INFINITY, NULL);  
    }
  }

  data->ref_decr();
}

void
Simulator::run(simtime stop_at)
{
  while (true)
  {
    simtime next_stop = MIN(stop_at, @schedule_next_step);

    /* 
     * Calculate all events from the priority queue until the next time
     * step is reached.
     */
    while (!@schedule_pq.empty())
    {
      NeuralEntity *top = @schedule_pq.top();
      if (top->get_schedule_at() >= next_stop)
        break;
      @schedule_current_time = top->get_schedule_at(); 
      @schedule_pq.pop();
      top->process(top->get_schedule_at());
    }

    if (@schedule_current_time >= stop_at)
      break;

    if (@schedule_stepping_list_root == NULL && @schedule_pq.empty())
      break;

    /* 
     * Calculate the entities that require stepped processing.
     */ 
    @schedule_current_time = @schedule_next_step; 

    if (@schedule_stepping_list_root != NULL)
    {
      // FIXME: collect all entities in an array. then process them.
    }

    @schedule_next_step += @schedule_step;
  }
}

void
Simulator::schedule_update(NeuralEntity *entity)
{
  @schedule_pq.update(entity);
}

void
Simulator::stat_record_fire_event(simtime at, NeuralEntity *source)
{
  ++@stat_fire_counter;
}
