#include "neural_entity.h"
#include "simulator.h"
#include <math.h>

NeuralEntity::NeuralEntity()
{
  @simulator = NULL;
  @id = NULL;
  @schedule_index = 0;
  @schedule_at = INFINITY;
  @schedule_stepping_list_prev = NULL;
  @schedule_stepping_list_next = NULL;
  @schedule_stepping_list_internal_next = NULL;
}

NeuralEntity::~NeuralEntity()
{
}


void
NeuralEntity::load(jsonHash *data)
{
}

void
NeuralEntity::dump(jsonHash *into)
{
}

static void
iter_disconnect(NeuralEntity *self, NeuralEntity *conn)
{
  self->disconnect(conn);
}

void
NeuralEntity::disconnect_all()
{
  each_connection(iter_disconnect);
}

void
NeuralEntity::schedule(simtime at)
{
  // FIXME: make sure that @schedule_at is reset
  // when the entity is removed from the pq.
  if (@schedule_at != at)
  {
    @schedule_at = at;
    @simulator->schedule_update(this);
  }
}

inline bool
NeuralEntity::schedule_stepping_enabled()
{
  return (@schedule_stepping_list_prev != NULL && 
          @schedule_stepping_list_next != NULL);
}

void
NeuralEntity::schedule_enable_stepping()
{
  if (!schedule_stepping_enabled())
  {
    NeuralEntity*& root = @simulator->schedule_stepping_list_root; 
    if (root != NULL)
    {
      @schedule_stepping_list_prev = root;
      @schedule_stepping_list_next = root->schedule_stepping_list_next;
      root->schedule_stepping_list_next = this; 
      @schedule_stepping_list_next->schedule_stepping_list_prev = this; 
    }
    else
    {
      root = this; 
      @schedule_stepping_list_prev = this;
      @schedule_stepping_list_next = this;
    }
  }
}

void
NeuralEntity::schedule_disable_stepping()
{
  if (schedule_stepping_enabled())
  {
    if (@schedule_stepping_list_prev != @schedule_stepping_list_next)
    {
      @schedule_stepping_list_prev->schedule_stepping_list_next = @schedule_stepping_list_next; 
      @schedule_stepping_list_next->schedule_stepping_list_prev = @schedule_stepping_list_prev;  
    }
    else
    {
      /*
       * We are the last entity in the stepping list.
       */
      @simulator->schedule_stepping_list_root = NULL;
      @schedule_stepping_list_prev = NULL;
      @schedule_stepping_list_next = NULL;
    }
  }
}

static bool
stimuli_accum(Stimulus &parent, const Stimulus &element, real tolerance)
{
  if ((element.at - parent.at) > tolerance) return false;

  if (isinf(element.weight))
  {
    /*
     * We only accumulate two infinitive values!
     */
    return (isinf(parent.weight) ? true : false);
  }

  parent.weight += element.weight;
  return true;
}

void
NeuralEntity::stimuli_add(simtime at, real weight)
{
  Stimulus s; s.at = at; s.weight = weight;
  if (@simulator->stimuli_tolerance >= 0.0)
  {
    if (@stimuli_pq.accumulate<real>(s, stimuli_accum, @simulator->stimuli_tolerance)) return;
  }
  @stimuli_pq.push(s);
  schedule(@stimuli_pq.top().at);
}

real
NeuralEntity::stimuli_sum(simtime until)
{
  real weight = 0.0;

  while (!@stimuli_pq.empty() && @stimuli_pq.top().at <= until)
  {
    weight += @stimuli_pq.top().weight;
    @stimuli_pq.pop();
  }

  /*
   * NOTE: we don't have to remove the entity from the schedule if the
   * pq is empty.
   */
  if (!@stimuli_pq.empty())
  {
    schedule(@stimuli_pq.top().at);
  }

  return weight;
}

real
NeuralEntity::stimuli_sum_inf(simtime until, bool &is_inf)
{
  real weight = 0.0;
  is_inf = false;

  while (!@stimuli_pq.empty() && @stimuli_pq.top().at <= until)
  {
    if (isinf(@stimuli_pq.top().weight))
    {
      is_inf = true;
    }
    else
    {
      weight += @stimuli_pq.top().weight;
    }
    @stimuli_pq.pop();
  }

  if (!@stimuli_pq.empty())
  {
    schedule(@stimuli_pq.top().at);
  }

  return weight;
}

void
NeuralEntity::set_simulator(Simulator *simulator)
{
  @simulator = simulator;
}

Simulator *
NeuralEntity::get_simulator() const
{
  return @simulator; 
}

void
NeuralEntity::set_id(const char *id)
{
  @id = id;
}

const char *
NeuralEntity::get_id() const
{
  return @id;
}
